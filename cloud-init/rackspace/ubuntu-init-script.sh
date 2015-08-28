#!/bin/bash -x

# DESCRIPTION: The following UserData script is created to configure a Rackspace Cloud server 
# with all the necessary things you might want. 
# Recommended flavor is a minimum 4-8GB as the disk partitions for /tmp and /var/log are 4-8GB
#
# Can be used from CLI with nova or supernova
# example: 
# supernova lincusa boot --image "Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)" --flavor performance1-8 --key-name {YOUR_KEY} --user-data "ubuntu-init-script.sh" --config-drive true {YOUR_SERVER_NAME}
# 
# Maintainer: andre [at] enthropia [dot] com
# Original: ivachkov [at] xi-group [dot] com
# 
# Requirements:
#	OS: Ubuntu 14.04 LTS
#	Repositories: 
#		...
#	Packages:
# 		htop, iotop, dstat, ...
#	PIP Packages:
#		
# 
# Additional information if necessary
# 	... 
# 

# Debian apt-get install function to eliminate prompts
export DEBIAN_FRONTEND=noninteractive
apt_get_install()
{
	DEBIAN_FRONTEND=noninteractive apt-get -y \
		-o DPkg::Options::=--force-confnew \
		install $@
}

# Configure disk layout 
INSTANCE_STORE_0="/dev/xvde"
# SWAP
IS0_PART_1="/dev/xvde1"
IS0_PART_1_SIZE="8G"
# TMP
IS0_PART_2="/dev/xvde2"
IS0_PART_2_SIZE="4G"
IS0_PART_2_MNT="/tmp"
# LOG
IS0_PART_3="/dev/xvde3"
IS0_PART_3_SIZE="8G"
IS0_PART_3_MNT="/var/log"
# MNT
IS0_PART_4="/dev/xvde4"
IS0_PART_4_SIZE=""
IS0_PART_4_MNT="/mnt"
# New Relic License
NEW_RELIC_LICENSE=""
# Rackspace Keys
RS_USERNAME=""
RS_KEY=""


# INSTANCE_STORE_1="/dev/xvdc"
# IS1_PART_1="/dev/xvdc1"
# IS1_PART_2="/dev/xvdc2"

# ... 

# Unmount /dev/xvdb if already mounted
MOUNTED=`df -h | awk '{print $1}' | grep $INSTANCE_STORE_0`
if [ ! -z "$MOUNTED" ]; then
	umount -f $INSTANCE_STORE_0
fi
# delete 4th partition if exists
PARTED_4=`fdisk -l | awk '{print $1}' | grep $IS0_PART_4`
if [ ! -z "$PARTED_4" ]; then
	(echo d; echo; echo w) | fdisk $INSTANCE_STORE_0
fi
# delete 3rd partition if exists
PARTED_3=`fdisk -l | awk '{print $1}' | grep $IS0_PART_3`
if [ ! -z "$PARTED_3" ]; then
	(echo d; echo; echo w) | fdisk $INSTANCE_STORE_0
fi
# delete 2nd partition if exists
PARTED_2=`fdisk -l | awk '{print $1}' | grep $IS0_PART_2`
if [ ! -z "$PARTED_2" ]; then
	(echo d; echo; echo w) | fdisk $INSTANCE_STORE_0
fi
# delete 1st partition if exists
PARTED_1=`fdisk -l | awk '{print $1}' | grep $IS0_PART_1`
if [ ! -z "$PARTED_1" ]; then
	(echo d; echo w) | fdisk $INSTANCE_STORE_0
fi

# Partition the disk (8GB for SWAP / Rest for /mnt)
# Create 1st Partition (SWAP)
#IS0_PART_1_FDISK="echo n; echo p; echo 1; echo; echo +$IS0_PART_1_SIZE; echo t; echo 82;"
# Create 2nd Partition (TMP)
#IS0_PART_2_FDISK="echo n; echo p; echo 2; echo; echo +$IS0_PART_2_SIZE;"
# Create 3rd Partition (LOG)
#IS0_PART_3_FDISK="echo n; echo p; echo 3; echo; echo +$IS0_PART_3_SIZE;"
# Create 4th Partition (MNT)
#IS0_PART_4_FDISK="echo n; echo p; echo 4; echo; echo;"
# Write Partition Table
(echo n; echo p; echo 1; echo; echo +$IS0_PART_1_SIZE; echo t; echo 82; echo n; echo p; echo 2; echo; echo +$IS0_PART_2_SIZE; echo n; echo p; echo 3; echo; echo +$IS0_PART_3_SIZE; echo n; echo p; echo 4; echo; echo; echo w) | fdisk $INSTANCE_STORE_0

# Make and enable swap
mkswap $IS0_PART_1
swapon $IS0_PART_1

# Make partitions and mount it
#TMP
mkfs.ext4 $IS0_PART_2
mkdir -p $IS0_PART_2_MNT
mount $IS0_PART_2 $IS0_PART_2_MNT
#fix permissions
chmod 1777 $IS0_PART_2_MNT

#MNT
mkfs.ext4 $IS0_PART_4
mkdir -p $IS0_PART_4_MNT
mount $IS0_PART_4 $IS0_PART_4_MNT

#Move Spool and Home to /mnt
mv /home /mnt/
ln -s /mnt/home /home
#mv /var/spool /mnt/
#ln -s /mnt/spool /var/spool

# Update /etc/fstab if necessary 
#sed -i s/$INSTANCE_STORE_0/$IS0_PART_2/g /etc/fstab
echo "$IS0_PART_1      none               swap    sw 0 0" >> /etc/fstab
echo "$IS0_PART_2      $IS0_PART_2_MNT               ext4    errors=remount-ro,noatime,barrier=0 0       1" >> /etc/fstab
echo "$IS0_PART_3      $IS0_PART_3_MNT               ext4    errors=remount-ro,noatime,barrier=0 0       1" >> /etc/fstab
echo "$IS0_PART_4      $IS0_PART_4_MNT               ext4    errors=remount-ro,noatime,barrier=0 0       1" >> /etc/fstab

# Add external repositories
# 
# Example 1: MongoDB
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
#echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
# 
# Example 2: Salt
# add-apt-repository ppa:saltstack/salt
# 
# Example 3: *Internal repository*
# curl --silent https://apt.mydomain.com/my.apt.gpg.key | apt-key add -
# curl --silent -o /etc/apt/sources.list.d/my.apt.list https://apt.mydomain.com/my.apt.list

# Update the packace indexes
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confnew" dist-upgrade

# Install basic APT packages and requirements
apt_get_install htop sysstat dstat iotop
# apt_get_install ... 
apt_get_install python-pip python-apt
apt_get_install ntp screen
apt_get_install apache2
apt_get_install mysql-server
apt_get_install php5 php-pear php5-common php5-cli php5-dev php5-apcu php5-gd php5-imagick
apt_get_install php5-mysql php5-mongo php5-sqlite php5-memcache php5-memcached 
apt_get_install php5-json php5-imap php5-gearman php5-curl php5-readline php5-sasl php5-xmlrpc php5-xsl php5-geoip php5-intl php5-mcrypt php5-oauth php5-pspell
# apt_get_install ... 

# Install PIP requirements
# pip install ... 

# Install New Relic
curl --silent https://download.newrelic.com/548C16BF.gpg | apt-key add -
echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list
echo newrelic-php5 newrelic-php5/application-name string "PHP Application" | debconf-set-selections
echo newrelic-php5 newrelic-php5/license-key string $NEW_RELIC_LICENSE | debconf-set-selections
apt-get update && apt_get_install newrelic-sysmond newrelic-php5
nrsysmond-config --set license_key=$NEW_RELIC_LICENSE
/etc/init.d/newrelic-sysmond start 

# Install Rackspace Monitoring
sh -c 'echo "deb http://stable.packages.cloudmonitoring.rackspace.com/ubuntu-14.04-x86_64 cloudmonitoring main" > /etc/apt/sources.list.d/rackspace-monitoring-agent.list'
wget -qO- https://monitoring.api.rackspacecloud.com/pki/agent/linux.asc | apt-key add -
apt-get update && apt-get install rackspace-monitoring-agent
rackspace-monitoring-agent --setup --username $RS_USERNAME --apikey $RS_KEY
rackspace-monitoring-agent start -D

# Install Rackspace Cloud Backup
wget 'http://agentrepo.drivesrvr.com/debian/cloudbackup-updater-latest.deb'
dpkg -i cloudbackup-updater-latest.deb
apt-get install -f
cloudbackup-updater -v
/usr/local/bin/driveclient --configure -u $RS_USERNAME -k $RS_KEY
service driveclient start

# Install Holland
curl --silent http://download.opensuse.org/repositories/home:/holland-backup/xUbuntu_14.10/Release.key | apt-key add -
echo 'deb http://download.opensuse.org/repositories/home:/holland-backup/xUbuntu_14.10/ ./' | tee /etc/apt/sources.list.d/holland.list
apt-get update && apt_get_install holland holland-common holland-mysqldump holland-mysqllvm

# Install page speed module
wget 'https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb'
dpkg -i mod-pagespeed-stable_current_amd64.deb
apt-get install -f

# Configure NTP
service ntp stop		# Stop ntp daemon to free NTP socket
sleep 3				# Give the daemon some time to exit
ntpdate pool.ntp.org		# Sync time
service ntp start		# Re-enable the NTP daemon

# Configure other system-specific settings ... 

# Configure automatic security updates
cat > /etc/apt/apt.conf.d/20auto-upgrades << "EOF"
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
/etc/init.d/unattended-upgrades restart

# Update system limits
cat > /etc/security/limits.d/my_limits.conf << "EOF"
*               soft    nofile          999999
*               hard    nofile          999999
root            soft    nofile          999999
root            hard    nofile          999999
EOF
ulimit -n 999999

# Update sysctl variables
cat > /etc/sysctl.d/my_sysctl.conf << "EOF"
net.core.somaxconn=65535
net.core.netdev_max_backlog=65535
# net.core.rmem_max=8388608
# net.core.wmem_max=8388608
# net.core.rmem_default=65536
# net.core.wmem_default=65536
# net.ipv4.tcp_rmem=8192 873800 8388608
# net.ipv4.tcp_wmem=4096 655360 8388608
# net.ipv4.tcp_mem=8388608 8388608 8388608
# net.ipv4.tcp_max_tw_buckets=6000000
# net.ipv4.tcp_max_syn_backlog=65536
# net.ipv4.tcp_max_orphans=262144
# net.ipv4.tcp_synack_retries = 2
# net.ipv4.tcp_syn_retries = 2
# net.ipv4.tcp_fin_timeout = 7
# net.ipv4.tcp_slow_start_after_idle = 0
# net.ipv4.ip_local_port_range = 2000 65000
# net.ipv4.tcp_window_scaling = 1
# net.ipv4.tcp_max_syn_backlog = 3240000
# net.ipv4.tcp_congestion_control = cubic
EOF
sysctl -p /etc/sysctl.d/my_sysctl.conf

# Configure Apache Mods
a2enmod authz_groupfile
a2enmod expires
a2enmod headers
a2enmod include
a2enmod reqtimeout
a2enmod rewrite
a2enmod ssl
cat > /etc/apache2/mods-enabled/expires-custom.conf << "EOF"
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresDefault A
    ExpiresByType image/x-icon A2592000
    ExpiresByType application/x-javascript A2592000
    ExpiresByType text/css A2592000
    ExpiresByType image/gif A604800
    ExpiresByType image/png A604800
    ExpiresByType image/jpeg A604800
    ExpiresByType text/plain A604800
    ExpiresByType application/x-shockwave-flash A604800
    ExpiresByType video/x-flv A604800
    ExpiresByType application/pdf A604800
    ExpiresByType text/html A
</IfModule>
EOF

# Configure PHP
cat > /etc/php5/apache2/conf.d/99-custom.ini << "EOF"
error_reporting = E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT
short_open_tag = On
EOF

# Configure Holland Backup
#cat > /etc/holland/holland.conf << "EOF"
#EOF
#cat > /root/.my.cnf << "EOF"
#[client]
#user="rackspace_backup"
#password=""
#EOF
#cat > /etc/holland/backupsets/default.conf << "EOF"
#[holland:backup]
#plugin = mysqldump
#backups-to-keep = 3
#auto-purge-failures = yes
#purge-policy = after-backup
#estimated-size-factor = 1.0
#
#[mysqldump]
#file-per-database       = yes

#[mysql:client]
#defaults-extra-file       = /root/.my.cnf
#EOF

# Create specific users and groups 
# addgroup ...
# useradd ... 
# usermod ...

# Create expected set of directories
DIRECTORIES="
	/var/log/...
	/run/...
	/srv/... 
	/opt/...
	"

#for DIRECTORY in $DIRECTORIES; do
#	mkdir -p $DIRECTORY
#	chown USER:GROUP $DIRECTORY	
#done

# Create custom_crontab
cat > /home/ubuntu/custom_crontab << "EOF"

EOF

# Enable custom cronjobs
su - ubuntu -c "/usr/bin/crontab /home/ubuntu/custom_crontab"

# Install main application / service 
# ...
# ... 

# Configure main application / service
# ... 
# ... 

# Make everythig survive reboot
cat > /etc/rc.local << "EOF"
#!/bin/sh

# Regenerate disk layout on ephemeral storage 
# ... 

# Start the application 
# ... 

EOF

# Start application
# service XXX restart
service apache2 restart
service mysql restart

# Tag the instance (NOTE: Depends on configure AWS CLI)
#INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
# aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=... 

# Mount /var/log partition after were done so we dont lose the cloud-init log
#LOG
mkfs.ext4 $IS0_PART_3
mkdir -p $IS0_PART_3_MNT
# stop rsyslog
service rsyslog stop
# move log dir to tmp
mkdir -p /tmp$IS0_PART_3_MNT
cp -prf $IS0_PART_3_MNT/* /tmp$IS0_PART_3_MNT
# mount log dir
mount $IS0_PART_3 $IS0_PART_3_MNT
# move log dir back and delete tmp dir
cp -prf /tmp$IS0_PART_3_MNT/* $IS0_PART_3_MNT
rm -rf /tmp$IS0_PART_3_MNT
# start rsyslog
service rsyslog start
# fix permissions
chmod 775 $IS0_PART_3_MNT
chown root:syslog $IS0_PART_3_MNT

# Mark successful execution
exit 0

