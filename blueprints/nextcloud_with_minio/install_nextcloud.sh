#!/bin/bash


#
#
#   Install LAMP stack with mariaDB
#
#
#   USAGE : ./script.sh  [DB_root_password]  [DB_nextcloud_user_password]  [minio_server]  [minio_root_password]  [nextcloud_admin_password]
#
#
#   ACCESS : IP/nextcloud avec le compte "admin" 
#	
#   https://wiki.crowncloud.net/?How_to_Install_LAMP_Stack_on_Rocky_Linux_9
#   https://wiki.crowncloud.net/?How_to_Install_NextCloud_on_Rocky_Linux_9
#   https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/automatic_configuration.html
#



# Recuperation des variables
# --------------------------
DB_root_password=$1
#echo "DB_root_password = " $DB_root_password					    # full admin sur la DB
DB_nextcloud_user_password=$2
#echo "DB_nextcloud_user_password = " $DB_nextcloud_user_password   # compte qui a les droits sur la DB nextcloud
minio_server=$3
minio_root_password=$4
nextcloud_admin_password=$5
#echo "nextcloud_admin_password = " $nextcloud_admin_password       # compte admin de nextcloud (UI)



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
dnf install -y yum-utils wget sshpass
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

#Create a User called nextcloud-user and grant permissions on the nextcloud_db database
mysql -u root  --password=$DB_root_password -e "GRANT ALL ON nextcloud_db.* TO 'nextcloud-user'@'localhost' IDENTIFIED BY '$DB_nextcloud_user_password';"
mysql -u root  --password=$DB_root_password -e "FLUSH PRIVILEGES;"



# install nextcloud
# -----------------
systemctl stop httpd

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


# On  recupere l'acces KEY/SECRET pour minio dans le fichier /root/minioTokenForNextcloud sur le serveur minio
full_line=`sshpass -p $minio_root_password ssh -o StrictHostKeyChecking=no root@$minio_server 'cat /root/minioTokenForNextcloud'`
#echo "full_line = $full_line"
ACCESS_KEY=`echo $full_line | awk '{print $3}'`
ACCESS_SECRET=`echo $full_line | awk '{print $6}'`
#echo $ACCESS_KEY
#echo $ACCESS_SECRET

echo "TOTO: DEBUT" >> /var/log/ALEXLOG.log
ls  /var/www/html/nextcloud/config/  >> /var/log/ALEXLOG.log
mv  /var/www/html/nextcloud/config/config.php    /var/www/html/nextcloud/config/_config.php.initial
echo "TOTO : MV FAIT"  >> /var/log/ALEXLOG.log
ls  /var/www/html/nextcloud/config/  >> /var/log/ALEXLOG.log
echo "TOTO : FIN"  >> /var/log/ALEXLOG.log

cat <<EOF > /var/www/html/nextcloud/config/config.php
<?php
	\$CONFIG = array (
     'objectstore' => [
        'class' => '\\\OC\\\Files\\\ObjectStore\\\S3',
        'arguments' => [
                'bucket' => 'nextcloud',
                'autocreate' => false,
                'hostname' => 'MINIO_SERVER',
                'key' => 'MINIO_KEY',
                'secret' => 'MINIO_SECRET',
                'port' => 9000,
                'use_ssl' => false,
                // required for some non-Amazon S3 implementations
                'use_path_style' => true,
        ],
     ],
	);
EOF
sed -i -e 's/MINIO_SERVER/'"$minio_server"'/g'  /var/www/html/nextcloud/config/config.php
sed -i -e 's/MINIO_KEY/'"$ACCESS_KEY"'/g'  /var/www/html/nextcloud/config/config.php
sed -i -e 's/MINIO_SECRET/'"$ACCESS_SECRET"'/g'  /var/www/html/nextcloud/config/config.php


# BY DEFAULT FILE ARE STORED IN /var/www/html/nextcloud/data 
# WE CAN REPLACE WITH S3 LIKE MINIO, mounts a bucket on an S3 object storage 
# To change data location update  /var/www/html/nextcloud/config/config.php
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/primary_storage.html
# Setup (celui qu'on fait dans la web UI sinon) et qui associe la database et cree le compte d'admin de l'UI nextcloud
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/automatic_configuration.html
# To automate install create a configuration file, called .../config/autoconfig.php, and set the file parameters as required
# /var/www/html/nextcloud/config/autoconfig.php is automatically removed after the initial configuration has been applied.
# Then all config is in /var/www/html/nextcloud/config/config.conf
# loglevel : 0=DEBUG(All activity), 1=INFO, 2=WARN, 3=ERROR, 5=FATAL
# log file : /var/www/html/nextcloud/data/nextcloud.log
cat <<EOF > /var/www/html/nextcloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql",
  "dbname"        => "nextcloud_db",
  "dbuser"        => "nextcloud-user",
  "dbpass"        => "DB_NEXTCLOUD_USER_PASSWORD",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
  "adminlogin"    => "admin",
  "adminpass"     => "ADMIN_PASSWORD",
  "directory"     => "/var/www/html/nextcloud/data/",
  "loglevel"      => "2",
);
EOF
sed -i -e 's/DB_NEXTCLOUD_USER_PASSWORD/'"$DB_nextcloud_user_password"'/g'  /var/www/html/nextcloud/config/autoconfig.php
sed -i -e 's/ADMIN_PASSWORD/'"$nextcloud_admin_password"'/g'  /var/www/html/nextcloud/config/autoconfig.php


# Enable permission for the Apache webserver user to access the NextCloud files
chown -R apache:apache /var/www/html/nextcloud/

# supprimer cet "index.html" qui ne sert a rien  (il est vide)
rm -f /var/www/html/nextcloud/data/index.html

# restart apache
systemctl start httpd



# IDEE D'AMELIORATION
#
# - separer la DB  t-tiers => 3tiers
# - Choix du path DATA pour le chemin nextcloud ??   (car pour minio c est deja dans /data avec un mount sur un disque externe)  
# - https ?
# - utiliser redis pour stockage password cross tier temporaire
# - variabiliser le niveau de log 
#