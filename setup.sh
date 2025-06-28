#!/bin/bash

USERID=$( id -u )
DOMAIN=""
IPDOMAIN=""
FORWARDER_1IP=""
FORWARDER_2IP=""
FORWARDERS=""
ALLOW_TRANSFER="none"
REVERSE_CFG=""
REVERSE_VARIATION=""
SLAVE_CFG=""
IP_SLAVE=""
IXFR="no"
DNSSEC_IN_CACHE=""
FWD_INT_IN_CACHE=""
FWD_IN_CACHE=""
TERM_EXTRA="false"
EXTRA_CHOICE=""
VIEW="Habilitar"
VIEW_NAME=""
ACL_ON=0
VIEW_ON="0"
LISTEN_ON="localhost"
ALLOW_QUERY="localhost"
ALLOW_RECURSION="localhost"
USE_ACL=""
CHOICE=""
CHOICE_3=""
MATCH_CLIENTS="localhost"
VAR=""
ACL_NAME=""
STAT_CFG=""

. ./functions.sh

test_user
check_net
check_pre_extant
update_install_bind
menu_select
restart_bind
