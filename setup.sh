#!/bin/bash

. functions.sh

test_user
clean-bind
update_install_bind
menu_select
restart-bind
