#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh

# Function install the components Neutron
neutron_install () {
	echocolor "Install the components Neutron"
	sleep 3

	apt install ovn-central python3-networking-ovn -y
}

# Function configure the common component
neutron_config_server_component () {
	echocolor "Configure the common component"
	sleep 3

	neutronfile=/etc/neutron/neutron.conf
	neutronfilebak=/etc/neutron/neutron.conf.bak
	cp $neutronfile $neutronfilebak
	egrep -v "^$|^#" $neutronfilebak > $neutronfile

	ops_del $neutronfile database connection
	ops_add $neutronfile DEFAULT \
		transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL

	ops_add $neutronfile DEFAULT auth_strategy keystone
	
	ops_add $neutronfile keystone_authtoken \
		www_authenticate_uri http://$HOST_CTL:5000
	ops_add $neutronfile keystone_authtoken \
		auth_uri http://$HOST_CTL:5000
	ops_add $neutronfile keystone_authtoken \
		memcached_servers $HOST_CTL:11211
	ops_add $neutronfile keystone_authtoken \
		auth_type password
	ops_add $neutronfile keystone_authtoken \
		project_domain_name default
	ops_add $neutronfile keystone_authtoken \
		user_domain_name default
	ops_add $neutronfile keystone_authtoken \
		project_name service
	ops_add $neutronfile keystone_authtoken \
		username neutron
	ops_add $neutronfile keystone_authtoken \
		password $NEUTRON_PASS

	ops_add $neutronfile oslo_concurrency \
		lock_path /var/lib/neutron/tmp
}

# Function configure relation things to OVN
ovn_config_relation () {
	echocolor "Configure relation things to OVN"

	/usr/share/openvswitch/scripts/ovs-ctl start  --system-id="random"
	
	ovn-nbctl set-connection ptcp:6641:$DB_MGNT_IP -- \
			set connection . inactivity_probe=60000
	ovn-sbctl set-connection ptcp:6642:$DB_MGNT_IP -- \
			set connection . inactivity_probe=60000
}

# Function restart installation
neutron_restart () {
	systemctl restart ovn-central
}

#######################
###Execute functions###
#######################

# Install the components Neutron
neutron_install

# Configure the common component
neutron_config_server_component

# Configure relation things to OVN
ovn_config_relation

# Restart installation
neutron_restart
