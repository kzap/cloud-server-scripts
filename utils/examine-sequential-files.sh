# From a Rackspace Sysadmin
# If you need to look through a bunch of files ending in numbers and run commands on them to see and compare their differences

for i in $(ls ps.log.{10..24}) ; do echo $i ; cat $i | grep httpd | wc -l ; done
