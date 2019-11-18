#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh
source db_num.sh

# Function update and upgrade for DATABASE
update_upgrade () {
	echocolor "Update DATABASE"
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

	sed -i 's|'"pool ntp.ubuntu.com        iburst maxsources 4"'| \
'"server $HOST_CTL iburst"'|g' $ntpfile

	sed -i 's/pool 0.ubuntu.pool.ntp.org iburst maxsources 1//g' $ntpfile
	sed -i 's/pool 1.ubuntu.pool.ntp.org iburst maxsources 1//g' $ntpfile
	sed -i 's/pool 2.ubuntu.pool.ntp.org iburst maxsources 2//g' $ntpfile

	timedatectl set-timezone Asia/Ho_Chi_Minh
	
	service chrony restart
}

# Function install OpenStack packages (python-openstackclient)
install_ops_packages () {
	echocolor "Install OpenStack client"
	sleep 3
	add-apt-repository cloud-archive:train -y
	apt-get update -y

	apt-get install python3-openstackclient -y
}

#######################
###Execute functions###
#######################

# Update and upgrade for DATABASE
update_upgrade

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# Install OpenStack packages (python-openstackclient)
install_ops_packages
