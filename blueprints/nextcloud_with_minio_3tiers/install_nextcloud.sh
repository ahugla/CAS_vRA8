#!/bin/bash


#
#
#   Install LAMP stack with mariaDB
#
#
#   USAGE : ./script.sh  [DB_nextcloud_user_password]  [minio_server_IP]  [minio_server_Hostname]  [nextcloud_admin_password]  [redis_password]  [loglevel]  [DB_server_Hostname]
#
#
#   ACCESS : https://IP/nextcloud avec le compte "admin" 
#	
#   https://wiki.crowncloud.net/?How_to_Install_LAMP_Stack_on_Rocky_Linux_9
#   https://wiki.crowncloud.net/?How_to_Install_NextCloud_on_Rocky_Linux_9
#   https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/automatic_configuration.html
#



# Recuperation des variables
# --------------------------

DB_nextcloud_user_password=$1                                       # compte de service qu'utilise nextcloud pour la DB
minio_server_IP=$2
minio_server_Hostname=$3
nextcloud_admin_password=$4                                         # compte admin de nextcloud (UI)
redis_password=$5                                                   # password de la base externe redis dans laquelle on a mis le accessKey/secretKey pour minio
loglevel=$6                                                         # loglevel ('debug', 'info' ou 'error') . Impacte httpd et nextcloud
DB_server_Hostname=$7                                               # hostname de la database




tempLogLocation="/tmp/install_script_variables.log"
# log des variables d'entree
echo "DB_nextcloud_user_password = " $DB_nextcloud_user_password    >>   $tempLogLocation
echo "minio_server_IP = " $minio_server_IP                          >>   $tempLogLocation
echo "minio_server_Hostname = " $minio_server_Hostname              >>   $tempLogLocation
echo "nextcloud_admin_password = " $nextcloud_admin_password        >>   $tempLogLocation
echo "redis_password = " $redis_password                            >>   $tempLogLocation
echo "loglevel = " $loglevel                                        >>   $tempLogLocation
echo "DB_server_Hostname = " $DB_server_Hostname                    >>   $tempLogLocation




# parametres
# ----------
redisServer=vra-000013.cpod-aria.az-lab.cloud-garage.net
redisPort=6379
DomainName=cpod-vrealize.az-fkd.cloud-garage.net
nextcloud_FQDN=$HOSTNAME.$DomainName                                # FQDN du serveur local (nextcloud)
nextcloud_IP=$(hostname  -I | cut -f1 -d' ')                        # IP du serveur local (nextcloud)
minio_FQDN=$minio_server_Hostname.$DomainName                       # FQDN du serveur minio
DB_server_FQDN=$DB_server_Hostname.$DomainName                      # FQDN de la Database
# parametres de log
# ----------------
#debug => {httpd=debug, nextcloud=0}      info => {httpd=info, nextcloud=1}       error => {httpd=error, nextcloud=3} 
loglevel_httpd=$loglevel
loglevel_nextcloud=1
if [ "$loglevel" == "debug" ]; then loglevel_nextcloud=0; fi
if [ "$loglevel" == "info" ];  then loglevel_nextcloud=1; fi
if [ "$loglevel" == "error" ]; then loglevel_nextcloud=3; fi



# log des parametres etablis
echo "redisServer = " $redisServer                                  >>   $tempLogLocation  
echo "redisPort = " $redisPort                                      >>   $tempLogLocation  
echo "DomainName = " $DomainName                                    >>   $tempLogLocation  
echo "nextcloud_IP = " $nextcloud_IP                                >>   $tempLogLocation  
echo "minio_FQDN = " $minio_FQDN                                    >>   $tempLogLocation  
echo "DB_server_FQDN = " $DB_server_FQDN                            >>   $tempLogLocation  
echo "nextcloud_FQDN = " $nextcloud_FQDN                            >>   $tempLogLocation  
echo "loglevel_httpd = $loglevel_httpd"                             >>   $tempLogLocation
echo "loglevel_nextcloud = $loglevel_nextcloud"                     >>   $tempLogLocation



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




# On recupere sur le redis les key access/secret du minio
# -------------------------------------------------------
dnf install -y redis
redis_auth=" -h $redisServer -p $redisPort --user dbadmin --pass $redis_password "
cmd1=" get  Minio_Access_Key_$minio_server_Hostname " 
ACCESS_KEY=`redis-cli $redis_auth $cmd1`
cmd2=" get  Minio_Secret_Key_$minio_server_Hostname " 
ACCESS_SECRET=`redis-cli $redis_auth $cmd2`





# Config de l'acces au minio en https
# -----------------------------------

# Pour que nextcloud puisse communiquer avec Minio, il faut :
#  1/ Dans /var/www/html/nextcloud/config/config.php:
#     'hostname' => 'MINIO_SERVER',     =>  OUI: hostname  (PAS IP sinon pb avec certif en https)
#     'port' =>  '9000'                 =>  OUI (9000 est aussi le port API et pas 40149)
#     'use_ssl' => true,                =>  OUI pour HTTPS
#  2/ Ajouter le certificat (public.crt) dans:  /var/www/html/nextcloud/resources/config/ca-bundle.crt
# Download the self-signed certif from minio website:
< /dev/null openssl s_client -connect $minio_FQDN:9000  | openssl x509 > /var/www/html/nextcloud/resources/config/certifminio.crt
# update du fichier dans lequel on met les certifs utilisés par nextcloud
echo " " >> /var/www/html/nextcloud/resources/config/ca-bundle.crt
echo "Serveur minio pour nextcloud" >> /var/www/html/nextcloud/resources/config/ca-bundle.crt
echo "============================" >> /var/www/html/nextcloud/resources/config/ca-bundle.crt
cat /var/www/html/nextcloud/resources/config/certifminio.crt >> /var/www/html/nextcloud/resources/config/ca-bundle.crt

# Pour que le code PHP (donc le systeme) puisse acceder en HTTPS il faut mettre a jour: /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem  (Never upadate manually)
# Il est fortement deconseillé d'ecrire directement ce fichier , il faut placer le certif dans '/usr/share/pki/ca-trust-source/anchors/' et faire 'update-ca-trust'
cp /var/www/html/nextcloud/resources/config/certifminio.crt  /usr/share/pki/ca-trust-source/anchors/
update-ca-trust

# config acces minio
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

# changement du loglevel de httpd ('LogLevel warn' par defaut)
sed -i -e 's/LogLevel warn/LogLevel '"$loglevel_httpd"'/g'  /etc/httpd/conf/httpd.conf

# restart apache
systemctl start httpd




# Install et config nextcloud  (equivalent a ce qui se passe lorsqu'on se connecte pour la premiere fois )
# ----------------------------
# sudo -u apache php /var/www/html/nextcloud/occ   status   => status (installé ou pas)
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#command-line-installation
#sudo -u apache php /var/www/html/nextcloud/occ
#sudo -u apache php /var/www/html/nextcloud/occ maintenance:install --help


sudo -u apache php /var/www/html/nextcloud/occ maintenance:install \
   --admin-user='admin' \
   --admin-pass=$nextcloud_admin_password \
   --database-host=$DB_server_FQDN \
   #--database-port='3306' \
   --database='mysql' \
   --database-name='nextcloud_db' \
   --database-user='nextcloud-user' \
   --database-pass=$DB_nextcloud_user_password \
   --data-dir='/var/www/html/nextcloud/data/' 


# ajout des URL autorisées pour les connexions
#sudo -u apache php /var/www/html/nextcloud/occ  config:system:get  nextcloud  trusted_domain
sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   trusted_domains  1 --value=$nextcloud_IP
sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   trusted_domains  2 --value=$nextcloud_FQDN


# Configurer le log level de nextcloud 
# loglevel : 0=DEBUG(All activity), 1=INFO, 2=WARN, 3=ERROR, 5=FATAL
#sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   loglevel --value='1'
sudo -u apache php /var/www/html/nextcloud/occ  config:system:set   loglevel --value=$loglevel_nextcloud




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
systemctl restart httpd





# nettoyage
rm -f /var/www/html/nextcloud/resources/config/certifminio.crt
dnf remove -y redis    # plus besoin






# IDEE D'AMELIORATION
#
#
# - Attendre la fin d'execution du script cloud init avec de marquer comme fini ??   vis une clé sur redis ?
#
# - integration dans Log Insight
#
#




