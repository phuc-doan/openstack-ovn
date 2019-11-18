#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh
source com_num.sh

# Function install the components Neutron
neutron_install () {
	echocolor "Install the components Neutron"
	sleep 3

	apt install openvswitch-common openvswitch-switch ovn-common ovn-host \
	  python3-networking-ovn networking-ovn-metadata-agent haproxy -y
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

# Function configure the networking-ovn-metadata-agent
networking-ovn-metadata-agent () {
	echocolor "Configure the networking-ovn-metadata-agent"
	sleep 3

	ovnmetadatafile=/etc/neutron/networking_ovn_metadata_agent.ini
	ovnmetadatafilebak=/etc/neutron/networking_ovn_metadata_agent.ini.bak
	cp $ovnmetadatafile $ovnmetadatafilebak
	egrep -v "^$|^#" $ovnmetadatafilebak > $ovnmetadatafile

	cat << EOF > $ovnmetadatafile
[DEFAULT]
nova_metadata_host = $CTL_MGNT_IP
metadata_proxy_shared_secret = $METADATA_SECRET
[ovs]
ovsdb_connection = unix:/var/run/openvswitch/db.sock
[agent]
[ovn]
ovn_sb_connection = tcp:$DB_VIP:6642
EOF
}

# Function configure things relation
neutron_config_relation () {
	ovs-vsctl add-br br-provider
	ovs-vsctl add-port br-provider ${COM_EXT_IF[$COM_NUM]}
	ip a flush ${COM_EXT_IF[$COM_NUM]}
	ip a add ${COM_EXT_IP[$COM_NUM]}/$PREFIX_EXT dev br-provider
	ip link set br-provider up
	ip r add default via $GATEWAY_EXT_IP
	systemd-resolve --set-dns=8.8.8.8 --interface=br-provider
	
	cat << EOF > /root/${HOST_COM[$COM_NUM]}-ovs-config.sh
ip a flush ${COM_EXT_IF[$COM_NUM]}
ip a add ${COM_EXT_IP[$COM_NUM]}/$PREFIX_EXT dev br-provider
ip link set br-provider up
ip r add default via $GATEWAY_EXT_IP
systemd-resolve --set-dns=8.8.8.8 --interface=br-provider
EOF

	chmod +x /root/${HOST_COM[$COM_NUM]}-ovs-config.sh
}

# Function configure relation things to OVN
ovn_config_relation () {
	echocolor "Configure relation things to OVN"

	/usr/share/openvswitch/scripts/ovs-ctl start --system-id="random"
	
	ovs-vsctl set open . external-ids:ovn-remote=tcp:$DB_VIP:6642
	ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
	ovs-vsctl set open . external-ids:ovn-encap-ip=${COM_DATAVM_IP[$COM_NUM]}
	
	ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=provider:br-provider
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
}

# Function restart installation
neutron_restart () {
	echocolor "Finalize installation"
	sleep 3
	systemctl restart nova-compute
	systemctl restart ovn-host
	systemctl restart networking-ovn-metadata-agent
}

#######################
###Execute functions###
#######################

# Install the components Neutron
neutron_install

# Configure the common component
neutron_config_server_component

# Configure the networking-ovn-metadata-agent
networking-ovn-metadata-agent

# Configure things relation
neutron_config_relation

# Configure relation things to ovs
ovn_config_relation

# Configure the Compute service to use the Networking service
neutron_config_compute_use_network
	
# Restart installation
neutron_restart