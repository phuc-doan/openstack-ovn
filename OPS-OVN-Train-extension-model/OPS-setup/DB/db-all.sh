#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh

#echocolor "IP address"
#source db-0-ipaddr.sh

echocolor "Environment"
source db-1-environment.sh

echocolor "Neutron"
source db-2-neutron.sh
