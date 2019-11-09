#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh

# Function update and upgrade for CONTROLLER
update_upgrade () {
	echocolor "Update controller"
	sleep 3
	apt-get update -y
}

# Function install crudini
install_crudini () {
	echocolor "Install crudini"
	sleep 3
	apt-get install -y crudini
}

# Function install and config NTP
install_ntp () {
	echocolor "Install NTP"
	sleep 3

	apt-get install chrony -y
	ntpfile=/etc/chrony/chrony.conf

	sed -i 's/pool ntp.ubuntu.com        iburst maxsources 4/ \
pool 2.debian.pool.ntp.org offline iburst/g' $ntpfile

	sed -i 's/pool 0.ubuntu.pool.ntp.org iburst maxsources 1/ \
server 0.asia.pool.ntp.org iburst/g' $ntpfile

	sed -i 's/pool 1.ubuntu.pool.ntp.org iburst maxsources 1/ \
server 1.asia.pool.ntp.org iburst/g' $ntpfile

	sed -i 's/pool 2.ubuntu.pool.ntp.org iburst maxsources 2//g' $ntpfile

	echo "allow $CIDR_MGNT" >> $ntpfile

	timedatectl set-timezone Asia/Ho_Chi_Minh
	
	systemctl restart chrony
}

# Function install OpenStack packages (python-openstackclient)
install_ops_packages () {
	echocolor "Install OpenStack client"
	sleep 3
	add-apt-repository cloud-archive:train -y
	apt-get update -y

	apt install python3-openstackclient -y
}

# Function install mysql
install_sql () {
	echocolor "Install SQL database - Mariadb"
	sleep 3
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
	add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://www.ftp.saix.net/DB/mariadb/repo/10.3/ubuntu bionic main'
	apt update -y
	
	apt-get install mariadb-server python-pymysql  -y

	sqlfile=/etc/mysql/mariadb.conf.d/99-openstack.cnf
	touch $sqlfile
	cat << EOF >$sqlfile
[mysqld]
bind-address = $CTL_MGNT_IP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

systemctl restart mysql
}

# Function install message queue
install_mq () {
	echocolor "Install Message queue (rabbitmq)"
	sleep 3

	apt-get install rabbitmq-server -y
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
}

# Function install Memcached
install_memcached () {
	echocolor "Install Memcached"
	sleep 3

	apt-get install memcached python-memcache -y
	memcachefile=/etc/memcached.conf
	sed -i 's|-l 127.0.0.1|'"-l $CTL_MGNT_IP"'|g' $memcachefile

	systemctl restart memcached
} 


#######################
###Execute functions###
#######################

# Update and upgrade for CONTROLLER
update_upgrade

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# Install OpenStack packages (python-openstackclient)
install_ops_packages

# Install SQL database (Mariadb)
install_sql

# Install Message queue (rabbitmq)
install_mq

# Install Memcached
install_memcached
