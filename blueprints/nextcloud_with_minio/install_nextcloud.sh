#!/bin/bash


#
#
#   Install LAMP stack with mariaDB
#
#
#   USAGE : ./script.sh  [DB_root_password]  [DB_nextcloud_user_password]  [minio_server_IP]  [minio_server_Hostname] [minio_root_password]  [nextcloud_admin_password]  [redis_password]
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
minio_server_IP=$3
minio_server_Hostname=$4
minio_root_password=$5
nextcloud_admin_password=$6
#echo "nextcloud_admin_password = " $nextcloud_admin_password       # compte admin de nextcloud (UI)
redis_password=$7                                                   # password de la base externe redis dans laquelle on a mis le accessKey/secretKey pour minio


# parametres
# ----------
redisServer=vra-009429.cpod-vrealize.az-fkd.cloud-garage.net
redisPort=6379
DomainName=cpod-vrealize.az-fkd.cloud-garage.net
nextcloud_FQDN=$HOSTNAME.$DomainName                                # FQDN du serveur local (nextcloud)
nextcloud_IP=$(hostname  -I | cut -f1 -d' ')                        # IP du serveur local (nextcloud)
minio_FQDN=$minio_server_Hostname.$DomainName                       # FQDN du serveur minio

cd /tmp



# install apache wer server (httpd)
# ---------------------------------
dnf install -y httpd httpd-tools mod_ssl 
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


# OLD METHOD (sshpass)
# ----------
# On  recupere l'acces KEY/SECRET pour minio dans le fichier /root/minioTokenForNextcloud sur le serveur minio
# full_line=`sshpass -p $minio_root_password ssh -o StrictHostKeyChecking=no root@$minio_server_IP 'cat /root/minioTokenForNextcloud'`
# echo "full_line = $full_line"
# ACCESS_KEY=`echo $full_line | awk '{print $3}'`
# ACCESS_SECRET=`echo $full_line | awk '{print $6}'`
# echo $ACCESS_KEY
# echo $ACCESS_SECRET


# On recupere sur le redis les key access/secret du minio
# -------------------------------------------------------
dnf install -y redis
redis_auth=" -h $redisServer -p $redisPort --user dbadmin --pass $redis_password "
cmd1=" get  Minio_Access_Key_$minio_server_Hostname " 
ACCESS_KEY=`redis-cli $redis_auth $cmd1`
cmd2=" get  Minio_Secret_Key_$minio_server_Hostname " 
ACCESS_SECRET=`redis-cli $redis_auth $cmd2`





# config de l'acces au minio
# --------------------------
# 'hostname' => 'MINIO_SERVER',      hostname, PAS IP (sinon pb avec certif en https)
# 'port' =>  '9000'                  9000 est aussi le port API (et pas 40149)
# 'use_ssl' => true,                 pour HTTPS
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
                'use_ssl' => true,
                // required for some non-Amazon S3 implementations
                'use_path_style' => true,
        ],
     ],
	);
EOF
sed -i -e 's/MINIO_SERVER/'"$minio_FQDN"'/g'  /var/www/html/nextcloud/config/config.php
sed -i -e 's/MINIO_KEY/'"$ACCESS_KEY"'/g'  /var/www/html/nextcloud/config/config.php
sed -i -e 's/MINIO_SECRET/'"$ACCESS_SECRET"'/g'  /var/www/html/nextcloud/config/config.php


# Enable permission for the Apache webserver user to access the NextCloud files
chown -R apache:apache /var/www/html/nextcloud/


# restart apache
systemctl start httpd



# install et config nextcloud  (equivalent a ce qui se passe lorsqu'on se connecte pour la premiere fois )
# ----------------------------
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#command-line-installation
#sudo -u apache php /var/www/html/nextcloud/occ
#sudo -u apache php /var/www/html/nextcloud/occ maintenance:install --help


sudo -u apache php /var/www/html/nextcloud/occ maintenance:install \
   --admin-user='admin' \
   --admin-pass=$nextcloud_admin_password \
   --database-host='localhost' \
   --database='mysql' \
   --database-name='nextcloud_db' \
   --database-user='nextcloud-user' \
   --database-pass=$DB_nextcloud_user_password \
   --data-dir='/var/www/html/nextcloud/data/' 


# ajout des URL autorisées pour les connexions
#sudo -u apache php /var/www/html/nextcloud/occ  config:system:get  nextcloud  trusted_domain
sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   trusted_domains  1 --value=$nextcloud_IP
sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   trusted_domains  2 --value=$nextcloud_FQDN


# Configurer le log level a 1
# loglevel : 0=DEBUG(All activity), 1=INFO, 2=WARN, 3=ERROR, 5=FATAL
sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   loglevel --value='1'


# inutile desormais car install et conf effectuée
rm -f /var/www/html/nextcloud/config/CAN_INSTALL


# Creation du raccourci vers le fichier de log dans /var/log/
ln -s  /var/www/html/nextcloud/data/nextcloud.log  /var/log/nextcloud.log



# Configuration HTTPS dans Apache
# -------------------------------
# path vers le certificat SSL d'apache:
# grep SSLCertificateFile /etc/httpd/conf.d/ssl.conf | grep -v "#"
#    =>   SSLCertificateFile /etc/pki/tls/certs/localhost.crt
#    =>   par defaut apache httpd recherche un /etc/pki/tls/certs/localhost.crt et la clé privée dans /etc/pki/tls/private/localhost.key

# voir date d'expiration
# openssl x509 -enddate -noout -in  /etc/pki/tls/certs/localhost.crt

# Generate a self-signed certificate 
cd /etc/pki/tls/certs/
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt -subj "/C=XX/ST=FR/L=Paris/O=Broadcom/OU=CMPSE/CN=$nextcloud_FQDN"
# on renomme et on met au bon endroit la clé privée
mv certificate.crt localhost.crt
mv privateKey.key /etc/pki/tls/private/localhost.key

# on redirige les requetes entrantes HTTP en HTTPS  (ip et fqdn)
cat <<EOF > /etc/httpd/conf.d/redirect_http.conf
<VirtualHost *:80>
   ServerName HOSTNAME
   Redirect permanent / https://FQDN/
</VirtualHost>
EOF
sed -i -e 's/HOSTNAME/'"$HOSTNAME"'/g'  /etc/httpd/conf.d/redirect_http.conf
sed -i -e 's/FQDN/'"$nextcloud_FQDN"'/g'  /etc/httpd/conf.d/redirect_http.conf

# restart apache
systemctl start httpd




<< COMMENTS
# convert crt to pem:
      openssl x509 -in cert.crt -out cert.pem

# import certif
sudo -u apache php /var/www/html/nextcloud/occ security:certificates:import /tmp/public.pem
COMMENTS




#  pour que nextcloud puisse communiquer avec Minio:
# ----------------------------------------------------
# dans /var/www/html/nextcloud/config/config.php:
#   'hostname' => 'MINIO_SERVER',     =>  OUI: hostname  (PAS IP sinon pb avec certif en https)
#   'port' =>  '9000'                 =>  OUI (9000 est aussi le port API et pas 40149)
#   'use_ssl' => true,                =>  OUI pour HTTPS
#  Ajouter le certificat (public.CRT) dans:  /var/www/html/nextcloud/resources/config/ca-bundle.crt
#  Get public key for minio from redis:
redis_auth=" -h $redisServer -p $redisPort --user dbadmin --pass $redis_password "
cmd3=" get  Minio_PublicCRT_$minio_server_Hostname " 
minio_publicCRT=`redis-cli $redis_auth $cmd3`
echo $minio_publicCRT >> /var/www/html/nextcloud/resources/config/temp

# IL FAUT REVENIR A LA LIGNE QUAND NECESSAIRE: 
#     apres le -----BEGIN CERTIFICATE----- 
#     avant le -----END CERTIFICATE-----
sed -i -e 's/-----BEGIN CERTIFICATE-----/-----BEGIN CERTIFICATE-----\n/g'  /var/www/html/nextcloud/resources/config/temp    
sed -i -e 's/-----END CERTIFICATE-----/\n-----END CERTIFICATE-----/g'      /var/www/html/nextcloud/resources/config/temp    
more  /var/www/html/nextcloud/resources/config/temp >> /var/www/html/nextcloud/resources/config/ca-bundle.crt

#rm -f /var/www/html/nextcloud/resources/config/temp                  ########################



# nettoyage
dnf remove -y redis    # plus besoin









# IDEE D'AMELIORATION
#
# - separer la DB  t-tiers => 3tiers
# - variabiliser le niveau de log 
# - acces a minio en https   https://min.io/docs/minio/linux/operations/network-encryption.html
