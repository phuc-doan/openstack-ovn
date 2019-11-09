#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh
source net_num.sh

# Function config NETWORK node
config_hostname () {
	echo "${HOST_NET[$NET_NUM]}" > /etc/hostname
	hostnamectl set-hostname ${HOST_NET[$NET_NUM]}

	cat << EOF >/etc/hosts
127.0.0.1	localhost

$CTL_MGNT_IP	$HOST_CTL
$DB_MGNT_IP	$HOST_DB
EOF

	for (( i=1; i <= ${#HOST_NET[*]}; i++ ))
	do
		echo "${NET_MGNT_IP[$i]}	${HOST_NET[$i]}" >> /etc/hosts
	done

	for (( i=1; i <= ${#HOST_COM[*]}; i++ ))
	do
		echo "${COM_MGNT_IP[$i]}	${HOST_COM[$i]}" >> /etc/hosts
	done
}

# Function IP address
config_ip () {
	cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${NET_EXT_IF[$NET_NUM]}:
      dhcp4: no
      dhcp6: no
      addresses: [${NET_EXT_IP[$NET_NUM]}/$PREFIX_EXT, ]
      gateway4: $GATEWAY_EXT_IP
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    ${NET_MGNT_IF[$NET_NUM]}:
      dhcp4: no
      dhcp6: no
      addresses: [${NET_MGNT_IP[$NET_NUM]}/$PREFIX_MGNT, ]
    $CTL_DATAVM_IF:
      dhcp4: no
      dhcp6: no
      addresses: [${NET_DATAVM_IP[$NET_NUM]}/$PREFIX_DATAVM, ]
EOF

	ip a flush ${NET_EXT_IF[$NET_NUM]}
	ip a flush ${NET_MGNT_IF[$NET_NUM]}
	ip a flush ${NET_DATAVM_IF[$NET_NUM]}
	netplan apply
}

#######################
###Execute functions###
#######################

# Config NETWORK node
echocolor "Config NETWORK node"
sleep 3
## Config hostname
config_hostname

## IP address
config_ip