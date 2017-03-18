#!/bin/bash
 
# perms_check.sh - checks if current mode of file matches the rpm db & warns if 
#                  mode is less restrictive. Based on DISA STIG RHEL-06-000518.
#
# author  : Chad Mayfield (code@chadmayfield.com)
# license : gplv3
#
# EXAMPLE OUTPUT:
# ---------------
# ACTUAL: 775 (should be 750) File: /etc/sudoers.d
# ACTUAL: 755 (should be 644) File: /etc/rc.d/rc.local
# ACTUAL: 644 (should be 444) File: /usr/share/man/man8/fsadm.8.gz
# ACTUAL: 755 (should be 750) File: /etc/firewalld
#
# TODO:
#  - fix the $perms_num filesystem perms sed statement to handle sticky bit
#    better as well as setuid/setgid files
#  - "optimize" loop to not run cmds more than once


# make sure we're on a redhat variant
if [ ! -f /etc/redhat-release ]; then
    echo "ERROR: Must be run from a Red Hat based system! (CentOS, RHEL, etc.)"
    exit 1
fi

# make sure we're root so we can read EVERY file on the filesystem
if [ $UID -ne 0 ]; then
    echo "ERROR: You must be root to run this script!"
    exit 1
fi

#rpm_pkgs=()

# query the rpmdb for files with modified modes (^.M) and
# read the list of files into an array to check later
readarray files <<< $(rpm -Va | grep '^.M' | cut -c14-)

echo "=================================================="
echo "ERROR! THE FOLLOWING FILE MODES DIFFER FROM RPMDB!"
echo "=================================================="

# iterate though each file
for i in ${files[@]}; do

    # based on file, find package owner
    pkg=$(rpm -qf $i)

    # add pkg if not already in array
#    if [[ "${rpm_pkgs[*]}" != *"$pkg"* ]]; then
#        # add $pkg to array
#        rpm_pkgs+=("$pkg")
#    fi

    # get "correct" perms from rpmdb based on package
    perms=$(rpm -q --queryformat "[%{FILEMODES:perms}  %{FILENAMES}\n]" $pkg |\
            egrep " ${i}$" | awk '{print $1}' | cut -c2-)

    # convert perms to numeric annotation ()
    perms_num=$(echo $perms | sed -e 's/rwx/7/g' -e 's/rwt/7/g' \
                                  -e 's/rw-/6/g' -e 's/rwT/6/g' \
                                  -e 's/r-x/5/g' -e 's/r-t/5/g' \
                                  -e 's/r--/4/g' -e 's/r-T/4/g' \
                                  -e 's/-wx/3/g' -e 's/-wt/3/g' \
                                  -e 's/-w-/2/g' -e 's/-wT/2/g' \
                                  -e 's/--x/1/g' -e 's/---/0/g' )

    # get actual filesystem perms
    aperms_num=$(stat -c "%a" $i)

    if [ $aperms_num -ge $perms_num ]; then
        printf "ACTUAL: %s (should be %s) File: %s\n" $aperms_num $perms_num $i
    fi
done

#EOF
