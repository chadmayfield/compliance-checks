#!/bin/bash
 
# perms_check.sh - checks if current mode of file matches the rpm db & warns if 
#                  mode is less restrictive. Based on DISA STIG RHEL-06-000518.
#
# author  : Chad Mayfield (chad@chd.my)
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

    # split $perms into 3 parts for owner/group/other
    # to check for special permissions and note them
    readarray a <<< $(echo $perms | fold -w 3)

    # initialize
    index=0
    spec_perms=0

    # check for special perms in array
    for j in ${a[@]}
    do
        #echo $j[${index}]

        # chart to remember specials perms
        #1--- Sticky Bit         2--- SGID
        #3--- Sticky Bit & SGID  4--- SUID
        #5--- Sticky Bit & SUID  6--- SGID & SUID
        #7--- Sticky Bit, SUID, SGID

        # set special perms if found
        if [[ $j =~ [sS] ]] && [ $index -eq 0 ]; then
             # setuid set (group)
             let spec_perms+=4
        elif [[ $j =~ [sS] ]] && [ $index -eq 1 ]; then
             # setgid set (owner)
             let spec_perms+=2
        elif [[ $j =~ [tT] ]] && [ $index -eq 2 ]; then
             # sticky bit set (other)
             let spec_perms+=1
        else
             :
        fi

        let index++
    done

    # now that we have special perms let's convert the regular
    # perms to numerical rep. it may be ugly, but it works!
    perms_num=$(echo $perms | sed -e 's/rw[xts]/7/g' \
                                  -e 's/rw[-TS]/6/g' \
                                  -e 's/r-[xts]/5/g' \
                                  -e 's/r-[-TS]/4/g' \
                                  -e 's/-w[xts]/3/g' \
                                  -e 's/-w[-TS]/2/g' \
                                  -e 's/--[xts]/1/g' \
                                  -e 's/--[-TS]/0/g' )

    # and combine them
    if [ $spec_perms -ne 0 ]; then
        perms_num=$(echo ${spec_perms}${perms_num})
    fi

    # get actual filesystem perms
    aperms_num=$(stat -c "%a" $i)

    if [ $aperms_num -gt $perms_num ]; then
        printf "ACTUAL: %s (should be %s) File: %s\n" $aperms_num $perms_num $i
    fi
done

echo " "

#EOF
