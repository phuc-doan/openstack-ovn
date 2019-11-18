#!/bin/bash
# Author Son Do Xuan

source ../function.sh
source ../config.sh

# Function create database for Neutron
neutron_create_db () {
	echocolor "Create database for Neutron"
	sleep 3

	cat << EOF | mysql -u root -p$MYSQL_PASS
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
IDENTIFIED BY '$NEUTRON_DBPASS';
EOF
}

# Function create the neutron service credentials
neutron_create_info () {
	echocolor "Set environment variable for admin user"
	source /root/admin-openrc
	echocolor "Create the neutron service credentials"
	sleep 3

	openstack user create --domain default --password $NEUTRON_PASS neutron
	openstack role add --project service --user neutron admin
	openstack service create --name neutron \
	  --description "OpenStack Networking" network
	openstack endpoint create --region RegionOne \
	  network public http://$HOST_CTL:9696
	openstack endpoint create --region RegionOne \
	  network internal http://$HOST_CTL:9696
	openstack endpoint create --region RegionOne \
	  network admin http://$HOST_CTL:9696
}

# Function install the components
neutron_install () {
	echocolor "Install the components"
	sleep 3
	
	apt install neutron-server neutron-plugin-ml2 python3-networking-ovn -y
}

# Function configure the server component
neutron_config_server_component () { 
	echocolor "Configure the server component"
	sleep 3
	neutronfile=/etc/neutron/neutron.conf
	neutronfilebak=/etc/neutron/neutron.conf.bak
	cp $neutronfile $neutronfilebak
	egrep -v "^$|^#" $neutronfilebak > $neutronfile

	ops_add $neutronfile database \
		connection mysql+pymysql://neutron:$NEUTRON_DBPASS@$HOST_CTL/neutron

	ops_add $neutronfile DEFAULT \
		core_plugin neutron.plugins.ml2.plugin.Ml2Plugin
	ops_add $neutronfile DEFAULT \
		service_plugins networking_ovn.l3.l3_ovn.OVNL3RouterPlugin
	ops_add $neutronfile DEFAULT \
		allow_overlapping_ips true

	ops_add $neutronfile DEFAULT \
		transport_url rabbit://openstack:$RABBIT_PASS@$HOST_CTL

	ops_add $neutronfile DEFAULT \
		auth_strategy keystone
	ops_add $neutronfile keystone_authtoken \
		www_authenticate_uri http://$HOST_CTL:5000
	ops_add $neutronfile keystone_authtoken \
		auth_url http://$HOST_CTL:5000
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

	ops_add $neutronfile DEFAULT \
		notify_nova_on_port_status_changes true
	ops_add $neutronfile DEFAULT \
		notify_nova_on_port_data_changes true
	ops_add $neutronfile nova \
		auth_url http://$HOST_CTL:5000
	ops_add $neutronfile nova \
		auth_type password
	ops_add $neutronfile nova \
		project_domain_name default
	ops_add $neutronfile nova \
		user_domain_name default
	ops_add $neutronfile nova \
		region_name RegionOne
	ops_add $neutronfile nova \
		project_name service
	ops_add $neutronfile nova \
		username nova
	ops_add $neutronfile nova \
		password $NOVA_PASS

	ops_add $neutronfile oslo_concurrency \
		lock_path /var/lib/neutron/tmp
}

# Function configure the Modular Layer 2 (ML2) plug-in
neutron_config_ml2 () {
	echocolor "Configure the Modular Layer 2 (ML2) plug-in"
	sleep 3
	ml2file=/etc/neutron/plugins/ml2/ml2_conf.ini
	ml2filebak=/etc/neutron/plugins/ml2/ml2_conf.ini.bak
	cp $ml2file $ml2filebak
	egrep -v "^$|^#" $ml2filebak > $ml2file
	
	ops_add $ml2file ml2 mechanism_drivers ovn
	ops_add $ml2file ml2 type_drivers local,flat,vlan,geneve
	ops_add $ml2file ml2 tenant_network_types geneve
	ops_add $ml2file ml2 extension_drivers port_security
	ops_add $ml2file ml2 overlay_ip_version 4
	
	ops_add $ml2file ml2_type_geneve vni_ranges 1:65536
	ops_add $ml2file ml2_type_geneve max_header_size 38
	
	ops_add $ml2file ml2_type_flat flat_networks provider
	ops_add $ml2file ml2_type_vlan network_vlan_ranges provider:1001:2000
	
	ops_add $ml2file securitygroup enable_security_group true
	
	
	ops_add $ml2file ovn ovn_metadata_enabled true
	ops_add $ml2file ovn ovn_nb_connection tcp:$DB_VIP:6641
	ops_add $ml2file ovn ovn_sb_connection tcp:$DB_VIP:6642
	ops_add $ml2file ovn ovn_l3_scheduler chance
	ops_add $ml2file ovn enable_distributed_floating_ip true
}

# Function configure the Compute service to use the Networking service
neutron_config_compute_use_network () {
	echocolor "Configure the Compute service to use the Networking service"
	sleep 3
	novafile=/etc/nova/nova.conf

	ops_add $novafile neutron auth_url http://$HOST_CTL:5000
	ops_add $novafile neutron auth_type password
	ops_add $novafile neutron project_domain_name default
	ops_add $novafile neutron user_domain_name default
	ops_add $novafile neutron region_name RegionOne
	ops_add $novafile neutron project_name service
	ops_add $novafile neutron username neutron
	ops_add $novafile neutron password $NEUTRON_PASS
	ops_add $novafile neutron service_metadata_proxy true
	ops_add $novafile neutron metadata_proxy_shared_secret $METADATA_SECRET
}

# Function populate the database
neutron_populate_db () {
	echocolor "Populate the database"
	sleep 3
	su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
}

# Function restart installation
neutron_restart () {
	service nova-api restart
	service neutron-server restart
}

#######################
###Execute functions###
#######################

# Create database for Neutron
neutron_create_db

# Create the neutron service credentials
neutron_create_info

# Install the components
neutron_install

# Configure the server component
neutron_config_server_component

# Configure the Modular Layer 2 (ML2) plug-in
neutron_config_ml2

# Configure the Compute service to use the Networking service
neutron_config_compute_use_network

# Populate the database
neutron_populate_db

# Restart installation
neutron_restart