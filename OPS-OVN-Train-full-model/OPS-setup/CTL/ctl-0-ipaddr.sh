#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh

# Function config hostname
config_hostname () {
	echo "$HOST_CTL" > /etc/hostname
	hostnamectl set-hostname $HOST_CTL

	cat << EOF >/etc/hosts
127.0.0.1	localhost

$CTL_MGNT_IP	$HOST_CTL
EOF

	for (( i=1; i <= ${#HOST_DB[*]}; i++ ))
	do
		echo "${DB_MGNT_IP[$i]}	${HOST_DB[$i]}" >> /etc/hosts
	done

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
    $CTL_EXT_IF:
      dhcp4: no
      dhcp6: no
      addresses: [$CTL_EXT_IP/$PREFIX_EXT, ]
      gateway4: $GATEWAY_EXT_IP
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    $CTL_MGNT_IF:
      dhcp4: no
      dhcp6: no
      addresses: [$CTL_MGNT_IP/$PREFIX_MGNT, ]
    $CTL_DATAVM_IF:
      dhcp4: no
      dhcp6: no
      addresses: [$CTL_DATAVM_IP/$PREFIX_DATAVM, ]
EOF

	ip a flush $CTL_EXT_IF
	ip a flush $CTL_MGNT_IF
	ip a flush $CTL_DATAVM_IF
	netplan apply
}

#######################
###Execute functions###
#######################

# Config CONTROLLER node
echocolor "Config CONTROLLER node"
sleep 3

## Config hostname
config_hostname

## IP address
config_ip
