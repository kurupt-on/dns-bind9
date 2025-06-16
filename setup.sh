#!/bin/bash

USERID=$( id -u )
DOMAIN=""
IPDOMAIN=""
FORWARDER_1IP=""
FORWARDER_2IP=""
ALLOW_TRANSFER="none"

. ./functions.sh

test_user
clean-bind
update_install_bind
menu_select
restart-bind
