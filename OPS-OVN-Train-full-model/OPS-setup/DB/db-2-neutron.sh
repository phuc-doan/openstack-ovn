#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh
source db_num.sh

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

# Function configure Keepalive for OVN
keepalive_config () {
	echocolor "Configure the Keepalive"
	sleep 3

	apt install keepalived -y
	
	keepalivedfile=/etc/keepalived/keepalived.conf
	touch $keepalivedfile
	
	db_priority=`expr 200 - $DB_NUM`
	
	cat << EOF > $keepalivedfile
global_defs {
   notification_email {
     sondoxuan@vccorp.vn
   }
   notification_email_from database$DB_NUM@mydomain.com
   smtp_server localhost
   smtp_connect_timeout 30
}

vrrp_instance VI_1 {
    state MASTER
    interface ${DB_MGNT_IF[$DB_NUM]}
    virtual_router_id 101
    priority $db_priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 123456
    }
    virtual_ipaddress {
        $DB_VIP
    }
}
EOF
	
	systemctl restart keepalived
}

# Function configure relation things to OVN
ovn_config_relation () {
	echocolor "Configure relation things to OVN"

	/usr/share/openvswitch/scripts/ovs-ctl start  --system-id="random"
	
	/usr/share/openvswitch/scripts/ovn-ctl stop_nb_ovsdb
	/usr/share/openvswitch/scripts/ovn-ctl stop_sb_ovsdb
	rm /etc/openvswitch/ovn*.db
	/usr/share/openvswitch/scripts/ovn-ctl stop_northd
	
	if [ $DB_NUM = 1 ]
	then
		echocolor "DATABASE MASTER"

		LOCAL_IP=${DB_MGNT_IP[$DB_NUM]}
		sudo /usr/share/openvswitch/scripts/ovn-ctl \
			--db-nb-cluster-local-addr=$LOCAL_IP start_nb_ovsdb

		sudo /usr/share/openvswitch/scripts/ovn-ctl \
			--db-sb-cluster-local-addr=$LOCAL_IP start_sb_ovsdb
			
		ovn-nbctl set-connection ptcp:6641:$DB_VIP -- \
			set connection . inactivity_probe=60000
		ovn-sbctl set-connection ptcp:6642:$DB_VIP -- \
			set connection . inactivity_probe=60000		
	else
		echocolor "DATABASE SLAVE"

		LOCAL_IP=${DB_MGNT_IP[$DB_NUM]}
		MASTER_IP=${DB_MGNT_IP[1]}

		/usr/share/openvswitch/scripts/ovn-ctl  \
			--db-nb-cluster-local-addr=$LOCAL_IP \
			--db-nb-cluster-remote-addr=$MASTER_IP start_nb_ovsdb

		/usr/share/openvswitch/scripts/ovn-ctl  \
			--db-sb-cluster-local-addr=$LOCAL_IP \
			--db-sb-cluster-remote-addr=$MASTER_IP start_sb_ovsdb
	fi	
			
	/usr/share/openvswitch/scripts/ovn-ctl start_northd
}

#######################
###Execute functions###
#######################

# Install the components Neutron
neutron_install

# Configure the common component
neutron_config_server_component

# Function configure Keepalive for OVN
keepalive_config

# Configure relation things to OVN
ovn_config_relation