#!/bin/bash


#
#
#   Install LAMP stack with mariaDB
#
#
#   USAGE : ./script.sh  [DB_root_password]  [DB_nextcloud_user_password]
#
#	
#   https://wiki.crowncloud.net/?How_to_Install_LAMP_Stack_on_Rocky_Linux_9
#   https://wiki.crowncloud.net/?How_to_Install_NextCloud_on_Rocky_Linux_9
#



# Recuperation des variables
# --------------------------
DB_root_password=$1
echo "DB_root_password = " $DB_root_password					   # full admin sur la DB
DB_nextcloud_user_password=$2
echo "DB_nextcloud_user_password = " $DB_nextcloud_user_password   # compte qui a les droits sur la DB nextcloud



cd /tmp



# install apache wer server (httpd)
# ---------------------------------
dnf install -y httpd httpd-tools
systemctl enable httpd
systemctl start httpd
systemctl status httpd


# install php
# ---------------
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y yum-utils wget
dnf install -y php php-zip php-intl php-mysqlnd php-dom php-simplexml php-xml php-xmlreader
dnf install -y php-curl php-exif php-ftp php-gd php-iconv php-json php-ldap php-mbstring php-posix php-sockets php-tokenizer php-opcache
php -v



# install mariadb and configure it
# --------------------------------
dnf install -y mariadb-server mariadb
systemctl enable mariadb
systemctl start mariadb
systemctl status mariadb

# set password for 'root'
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_root_password';"
mysql -e "FLUSH PRIVILEGES;"
systemctl restart mariadb

#mysql -u root -p
#MariaDB [(none)]> SHOW DATABASES;
#+--------------------+
#| Database           |
#+--------------------+
#| information_schema |
#| mysql              |
#| performance_schema |
#+--------------------+
#4 rows in set (0.00 sec)

# create nextcloud_db database for nextcloud
mysql -u root  --password=$DB_root_password -e  "CREATE DATABASE nextcloud_db;"
#mysql -u root -p
#MariaDB [(none)]> SHOW DATABASES;
#+--------------------+
#| Database           |
#+--------------------+
#| information_schema |
#| mysql              |
#| nextcloud_db       |
#| performance_schema |
#+--------------------+
#4 rows in set (0.00 sec)

#Create a User called nextcloud-user and grant permissions on the nextcloud-db database
mysql -u root  --password=$DB_root_password -e "GRANT ALL ON nextcloud_db.* TO 'nextcloud-user'@'localhost' IDENTIFIED BY '$DB_nextcloud_user_password';"
mysql -u root  --password=$DB_root_password -e "FLUSH PRIVILEGES;"



# install nextcloud
# -----------------
# download NextCloud
wget https://download.nextcloud.com/server/releases/nextcloud-24.0.3.zip

# extract file into the folder /var/www/html/
unzip nextcloud-24.0.3.zip -d /var/www/html/

# Create a directory to store the user data,
mkdir -p /var/www/html/nextcloud/data

# Enable permission for the Apache webserver user to access the NextCloud files
chown -R apache:apache /var/www/html/nextcloud/

# restart apache
systemctl restart httpd

