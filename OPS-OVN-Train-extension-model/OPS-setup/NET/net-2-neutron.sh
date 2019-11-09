#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh
source net_num.sh

# Function install the components Neutron
neutron_install () {
	echocolor "Install the components Neutron"
	sleep 3

	apt install openvswitch-common openvswitch-switch \
	  ovn-common ovn-host python3-networking-ovn -y
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

# Function configure things relation
neutron_config_relation () {
	ovs-vsctl add-br br-provider
	ovs-vsctl add-port br-provider ${NET_EXT_IF[$NET_NUM]}
	ip a flush ${NET_EXT_IF[$NET_NUM]}
	ip a add ${NET_EXT_IP[$NET_NUM]}/$PREFIX_EXT dev br-provider
	ip link set br-provider up
	ip r add default via $GATEWAY_EXT_IP
	systemd-resolve --set-dns=8.8.8.8 --interface=br-provider
	
	cat << EOF > /root/${HOST_NET[$NET_NUM]}-ovs-config.sh
ip a flush ${NET_EXT_IF[$NET_NUM]}
ip a add ${NET_EXT_IP[$NET_NUM]}/$PREFIX_EXT dev br-provider
ip link set br-provider up
ip r add default via $GATEWAY_EXT_IP
systemd-resolve --set-dns=8.8.8.8 --interface=br-provider
EOF

	chmod +x /root/${HOST_NET[$NET_NUM]}-ovs-config.sh
}

# Function configure relation things to OVN
ovn_config_relation () {
	echocolor "Configure relation things to OVN"

	/usr/share/openvswitch/scripts/ovs-ctl start --system-id="random"
	
	ovs-vsctl set open . external-ids:ovn-remote=tcp:$DB_MGNT_IP:6642
	ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
	ovs-vsctl set open . external-ids:ovn-encap-ip=${NET_DATAVM_IP[$NET_NUM]}
	
	ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=provider:br-provider
	
	ovs-vsctl set open . external-ids:ovn-cms-options="enable-chassis-as-gw"
}

# Function restart installation
neutron_restart () {
	echocolor "Finalize installation"
	sleep 3
	systemctl restart ovn-host
}

#######################
###Execute functions###
#######################

# Install the components Neutron
neutron_install

# Configure the common component
neutron_config_server_component

# Configure things relation
neutron_config_relation

# Configure relation things to OVN
ovn_config_relation

# Restart installation
neutron_restart