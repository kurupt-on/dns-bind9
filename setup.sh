#!/bin/bash

. functions.sh
USERID=$( id -u )
DOMAIN=""
IPDOMAIN=""
FORWARDER_1IP=""
FORWARDER_2IP=""

test-user
clean-bind
update_install
menu_select
restart-bind
