#!/bin/bash
#Author Son Do Xuan

source ../function.sh
source ../config.sh

echocolor "Neutron"
source ctl-5-neutron-selfservice.sh

echocolor "Horizon"
source ctl-6-horizon.sh

echocolor "Create Network and Flavor"
source ctl-7-create_network.sh
