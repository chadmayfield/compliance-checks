#!/bin/bash

# get_www_chiphers.sh - connect to site and get available ciphers

# exit on errors
set -e

usage="e.g. $0 [nmap|sslscan|ssltest|openssl] site.com port"
method=$1
site=$2
port=$3

if ! [ $# -ge 2 ]; then
    echo "ERROR: You must supply at least two arguments! A method to connect,"
    echo "a site for the connection, and optionally a port (default uses 443)"
    echo "  $usage"
    exit 1
fi

# need a valid discovery method
if [[ $method =~ "m/(nmap|sslscan|openssl)/" ]]; then
    echo "ERROR: Invalid option: $1! Please use a valid option."
    echo "  $usage"
    exit 1
#else
#    echo "Valid method: $method"
fi

regex='(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
# need a valid website to test
if [[ $site =~ $regex ]]; then
    echo "ERROR: Invalid URL provided, please try again with proper URL."
    echo "  $usage"
    exit 1
#else
#    echo "Valid URL $site"
fi

# need a valid port number
if [ -z ${3+x} ]; then
    # not set
    port="443"
else
    if ! [[ "$3" =~ ^[0-9]+$ ]]; then
#       `if [ "$3" -gt 65536 ]; then
         echo "ERROR: Invalid port: $3! Please use a valid port."
         echo "  $usage"
         exit 1
#        fi
#    else
#       echo "Valid port: $3"
    fi
fi

use_nmap() {
    # comfort food for the hungry packet pounder
    command -v nmap >/dev/null 2>&1 || { \
        echo >&2 "ERROR: You must install nmap to continue!"; exit 1; }

    echo "Enumerating ciphers using nmap..."

    command nmap --script ssl-enum-ciphers -p $port $site
}

use_openssl() {
    # how in the world don't you have openssl?!
    command -v openssl >/dev/null 2>&1 || { \
        echo >&2 "ERROR: You must install openssl to continue!"; exit 1; }

    echo "Enumerating cipher list using $(openssl version)..."

    SERVER="${site}:${port}"
    ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

}

use_sslscan() {
    # using https://www.ssllabs.com/ssltest/index.html
    #       https://github.com/ssllabs/ssllabs-scan
    command -v sslscan >/dev/null 2>&1 || { \
        echo >&2 "ERROR: You must install sslscan to continue!"; exit 1; }

    echo "Enumerating cipher list using sslscan..."
}

case "$method" in
    nmap)
        use_nmap
        ;;
    sslscan)
        #use_sslscan
        echo "Coming soon! Not yet implemented."
        ;;
    openssl)
        #use_openssl
        echo "Coming soon! Not yet implemented."
        ;;
    *)
        echo "ERROR: Unknown option: $method"
        ;;
esac

#EOF
