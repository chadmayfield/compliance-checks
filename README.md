# compliance_checks

Anyone who has had the 'pleasure' and opportunity to harden a system based on DISA STIG requirments knows how teadeous it is.  Here I have placed some small scripts that I have written to make hardening and mitigation documentation easier.

## perms_check.sh

Based on RHEL-06-000518. This script will check the current mode of a file on the filesystem with that of the RPM DB and warn if the permission is less restrictive. It doesn't care if it is more restrictive since that will usually be more secure.

