#!/bin/bash -x

# DESCRIPTION: The following UserData script is created to ... 
# 
# Maintainer: ivachkov [at] xi-group [dot] com
# 
# Requirements:
#	OS: Ubuntu 14.04 LTS
#	Repositories: 
#		...
#	Packages:
# 		htop, iotop, dstat, ...
#	PIP Packages:
#		boto, awscli, ...
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
IS0_PART_1="/dev/xvde1"
IS0_PART_2="/dev/xvde2"

# INSTANCE_STORE_1="/dev/xvdc"
# IS1_PART_1="/dev/xvdc1"
# IS1_PART_2="/dev/xvdc2"

# ... 

# Unmount /dev/xvdb if already mounted
MOUNTED=`df -h | awk '{print $1}' | grep $INSTANCE_STORE_0`
if [ ! -z "$MOUNTED" ]; then
	umount -f $INSTANCE_STORE_0
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
(echo n; echo p; echo 1; echo 2048; echo +8G; echo t; echo 82; echo n; echo p; echo 2; echo; echo; echo w) | fdisk $INSTANCE_STORE_0

# Make and enable swap
mkswap $IS0_PART_1
swapon $IS0_PART_1

# Make /mnt partition and mount it
mkfs.ext4 $IS0_PART_2
mount $IS0_PART_2 /mnt

# Update /etc/fstab if necessary 
#sed -i s/$INSTANCE_STORE_0/$IS0_PART_2/g /etc/fstab
echo "$IS0_PART_2      /mnt               ext4    errors=remount-ro,noatime,barrier=0 0       1" >> /etc/fstab
echo "$IS0_PART_1      none               swap    sw 0 0" >> /etc/fstab

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

# Holland
curl --silent http://download.opensuse.org/repositories/home:/holland-backup/xUbuntu_14.10/Release.key | apt-key add -
echo 'deb http://download.opensuse.org/repositories/home:/holland-backup/xUbuntu_14.10/ ./' | tee /etc/apt/sources.list.d/holland.list

# New Relic
NEW_RELIC_LICENSE=""
curl --silent https://download.newrelic.com/548C16BF.gpg | apt-key add -
echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list
echo newrelic-php5 newrelic-php5/application-name string "PHP Application" | debconf-set-selections
echo newrelic-php5 newrelic-php5/license-key string $NEW_RELIC_LICENSE | debconf-set-selections

# Update the packace indexes
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confnew" dist-upgrade

# Install basic APT packages and requirements
apt_get_install htop sysstat dstat iotop
# apt_get_install ... 
apt_get_install python-pip
apt_get_install ntp
apt_get_install apache2
apt_get_install mysql-server
apt_get_install php5 php-pear php5-common php5-cli php5-dev php5-apcu php5-gd php5-imagick
apt_get_install php5-mysql php5-mongo php5-sqlite php5-memcache php5-memcached 
apt_get_install php5-json php5-imap php5-gearman php5-curl php5-readline php5-sasl php5-snmp php5-xmlrpc php5-xsl php5-geoip php5-intl php5-mcrypt php5-oauth php5-pspell
apt_get_install newrelic-sysmond newrelic-php5
# apt_get_install ... 

# Install PIP requirements
# pip install ... 

# Configure NTP
service ntp stop		# Stop ntp daemon to free NTP socket
sleep 3				# Give the daemon some time to exit
ntpdate pool.ntp.org		# Sync time
service ntp start		# Re-enable the NTP daemon

# Configure other system-specific settings ... 
nrsysmond-config --set license_key=$NEW_RELIC_LICENSE

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

for DIRECTORY in $DIRECTORIES; do
	mkdir -p $DIRECTORY
	chown USER:GROUP $DIRECTORY	
done

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
/etc/init.d/newrelic-sysmond start 
service apache2 restart
service mysql restart

# Tag the instance (NOTE: Depends on configure AWS CLI)
#INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
# aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=... 

# Mark successful execution
exit 0

