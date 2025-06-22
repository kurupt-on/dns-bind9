#!/bin/bash

USERID=$( id -u )
DOMAIN=""
IPDOMAIN=""
FORWARDER_1IP=""
FORWARDER_2IP=""
ALLOW_TRANSFER="none"
REVERSE_CFG=""
REVERSE_VARIATION=""
SLAVE_CFG=""
IP_SLAVE=""
IXFR="no"
DNSSEC_IN_CACHE=""
FWD_INT_IN_CACHE=""
FWD_IN_CACHE=""

. ./functions.sh

test_user
check_net
check_pre_extant
update_install_bind
menu_select
restart-bind
