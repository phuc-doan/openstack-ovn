#!/bin/bash
#Author Son Do Xuan

##########################################
#### Set local variable  for scripts #####
##########################################

echocolor "Set local variable for scripts"
sleep 3

#  Ipaddress variable and Hostname variable
## Assigning IP for controller node
CTL_EXT_IP=10.5.11.111
CTL_EXT_NETMASK=255.255.252.0
CTL_EXT_IF=eth0
CTL_MGNT_IP=20.20.1.111
CTL_MGNT_NETMASK=255.255.255.0
CTL_MGNT_IF=eth1
CTL_DATAVM_IP=20.20.2.111
CTL_DATAVM_NETMASK=255.255.255.0
CTL_DATAVM_IF=eth2

## Assigning IP for Compute host
COM_EXT_IP[1]=10.5.11.121
COM_EXT_NETMASK[1]=255.255.252.0
COM_EXT_IF[1]=eth0
COM_MGNT_IP[1]=20.20.1.121
COM_MGNT_NETMASK[1]=255.255.255.0
COM_MGNT_IF[1]=eth1
COM_DATAVM_IP[1]=20.20.2.121
COM_DATAVM_NETMASK[1]=255.255.255.0
COM_DATAVM_IF[1]=eth2

COM_EXT_IP[2]=10.5.11.122
COM_EXT_NETMASK[2]=255.255.252.0
COM_EXT_IF[2]=eth0
COM_MGNT_IP[2]=20.20.1.122
COM_MGNT_NETMASK[2]=255.255.255.0
COM_MGNT_IF[2]=eth1
COM_DATAVM_IP[2]=20.20.2.122
COM_DATAVM_NETMASK[2]=255.255.255.0
COM_DATAVM_IF[2]=eth2

## Gateway for EXT network
GATEWAY_EXT_IP=10.5.8.1
CIDR_EXT=10.5.8.0/22
CIDR_MGNT=20.20.1.0/24
CIDR_DATAVM=20.20.2.0/24
PREFIX_EXT=22
PREFIX_MGNT=24
PREFIX_DATAVM=24

## Hostname variable
HOST_CTL=sondx-controller
HOST_COM[1]=sondx-compute1
HOST_COM[2]=sondx-compute2

# Password for node, node: The password for all nodes must be the same
NODE_DEFAULT_PASS="welcome123"

CTL_PASS=$NODE_DEFAULT_PASS
COM_PASS[1]=$NODE_DEFAULT_PASS
COM_PASS[2]=$NODE_DEFAULT_PASS

# Password for service
SERVICE_DEFAULT_PASS="Welcome123"

ADMIN_PASS=$SERVICE_DEFAULT_PASS
DEMO_PASS=$SERVICE_DEFAULT_PASS
MYSQL_PASS=$SERVICE_DEFAULT_PASS
RABBIT_PASS=$SERVICE_DEFAULT_PASS
KEYSTONE_DBPASS=$SERVICE_DEFAULT_PASS
GLANCE_DBPASS=$SERVICE_DEFAULT_PASS
GLANCE_PASS=$SERVICE_DEFAULT_PASS
METADATA_SECRET=$SERVICE_DEFAULT_PASS
NEUTRON_DBPASS=$SERVICE_DEFAULT_PASS
NEUTRON_PASS=$SERVICE_DEFAULT_PASS
PLACEMENT_DBPASS=$SERVICE_DEFAULT_PASS
PLACEMENT_PASS=$SERVICE_DEFAULT_PASS
NOVA_DBPASS=$SERVICE_DEFAULT_PASS
NOVA_PASS=$SERVICE_DEFAULT_PASS