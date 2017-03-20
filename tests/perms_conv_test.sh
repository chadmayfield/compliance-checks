#!/bin/bash

# perms_conv_test.sh - verfiy the sed statement for linux letter to number
#                      permissions conversion works, and converts ALL
#                      possible linux permission combos, all 4096
#
# author  : Chad Mayfield (chad@chd.my)
# license : gplv3

# download list of all perms and clean them up creating a pseudo-hash
readarray allperms <<< $(wget -qO- http://ixbrian.com/unixpermissions.html | egrep -A1 '[0-9][0-9][0-9][0-9]' | cut -c5- | awk -F "<" '{print $1}' | sed '/^$/d' | awk '{key=$0; getline; print key "|" $0;}')

for i in ${allperms[@]}
do
    # set vars for each side of the pseudo-hash
    num_perms=$(echo $i | awk -F"|" '{print $1}')
    ltr_perms=$(echo $i | awk -F"|" '{print $2}')

    # split $ltr_perms into 3 parts for owner/group/other
    # to check for special permissions and note them
    readarray a <<< $(echo $ltr_perms | fold -w 3)

    # initialize
    index=0
    spec_perms=0

    # check for special perms in array
    for j in ${a[@]}
    do
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

    # finally convert any permissions into numeric notation
    ltr_perms_conv=$(echo $ltr_perms | sed -e 's/rw[xts]/7/g' \
                                           -e 's/rw[-TS]/6/g' \
                                           -e 's/r-[xts]/5/g' \
                                           -e 's/r-[-TS]/4/g' \
                                           -e 's/-w[xts]/3/g' \
                                           -e 's/-w[-TS]/2/g' \
                                           -e 's/--[xts]/1/g' \
                                           -e 's/--[-TS]/0/g' )

    # add the special perms to the perms
    ltr_perms_conv=${spec_perms}${ltr_perms_conv}

    # compare to make sure we have them correct
    if [ $num_perms -ne $ltr_perms_conv ]; then
        echo "INCORRECT PERMS!"
        echo "\$num_perms = $num_perms"
        echo "\$ltr_perms = $ltr_perms"
        echo "\$ltr_perms_conv = ${ltr_perms_conv}"
    fi
#    sleep 1
#    echo "$ltr_perms_conv (${i})"
done

#EOF
