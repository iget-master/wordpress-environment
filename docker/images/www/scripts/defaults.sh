#!/bin/bash
# This script contains the default values used to setup the image

#################
# MySql Defaults
#################

MYSQL_ROOT_PASSWORD=wordpress

###########################
# Don't change below this #
###########################

debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/method select tcp"
debconf-set-selections <<< "phpmyadmin  phpmyadmin/remote/host select mysql"
debconf-set-selections <<< "phpmyadmin  phpmyadmin/remote/port string 3306"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect nginx"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean false"

debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"