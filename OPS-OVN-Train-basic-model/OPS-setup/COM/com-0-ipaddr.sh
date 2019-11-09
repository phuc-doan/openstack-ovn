#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh
source com_num.sh

# Function config COMPUTE node
config_hostname () {
	echo "${HOST_COM[$COM_NUM]}" > /etc/hostname
	hostnamectl set-hostname ${HOST_COM[$COM_NUM]}

	cat << EOF >/etc/hosts
127.0.0.1	localhost

$CTL_MGNT_IP	$HOST_CTL
EOF

	for (( i=1; i <= ${#HOST_COM[*]}; i++ ))
	do
		echo "${COM_MGNT_IP[$i]}	${HOST_COM[$i]}" >> /etc/hosts
	done
	
	for (( i=1; i <= ${#HOST_BLK[*]}; i++ ))
	do
		echo "${BLK_MGNT_IP[$i]}	${HOST_BLK[$i]}" >> /etc/hosts
	done
}

# Function IP address
config_ip () {
	cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${COM_EXT_IF[$COM_NUM]}:
      dhcp4: no
      dhcp6: no
      addresses: [${COM_EXT_IP[$COM_NUM]}/$PREFIX_EXT, ]
      gateway4: $GATEWAY_EXT_IP
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    ${COM_MGNT_IF[$COM_NUM]}:
      dhcp4: no
      dhcp6: no
      addresses: [${COM_MGNT_IP[$COM_NUM]}/$PREFIX_MGNT, ]
    $CTL_DATAVM_IF:
      dhcp4: no
      dhcp6: no
      addresses: [${COM_DATAVM_IP[$COM_NUM]}/$PREFIX_DATAVM, ]
EOF

	ip a flush ${COM_EXT_IF[$COM_NUM]}
	ip a flush ${COM_MGNT_IF[$COM_NUM]}
	ip a flush ${COM_DATAVM_IF[$COM_NUM]}
	netplan apply
}

#######################
###Execute functions###
#######################

# Config COMPUTE node
echocolor "Config COMPUTE node"
sleep 3
## Config hostname
config_hostname

## IP address
config_ip