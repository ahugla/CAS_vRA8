#   INSTALLATION DE mariaDB SUR CENTOS 7.x
#
#  v1.0
#
#  Alexandre Hugla
#  15/04/2021
#
#
#  USAGE :  install_mariaDB.sh [password]
#



# Recuperation des variables
DB_password=$1   #  utilisé pour l'acces DB à 'root' et 'testuser'


# recup du repo git
cd /tmp/
curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/mariaDB/dump.sql



# install MySLQ
yum install -y  git wget vim mariadb-server
systemctl start mariadb
systemctl enable mariadb


# Allow remote connections
# /etc/mysql/mysql.conf.d/mysqld.cnf


# set password for root
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$DB_password') WHERE User = 'root'"
systemctl restart mariadb

#mysql -u root -p
#MariaDB [(none)]> SHOW DATABASES;
#+--------------------+
#| Database           |
#+--------------------+
#| information_schema |
#| mysql              |
#| performance_schema |
#| test               |
#+--------------------+
#4 rows in set (0.00 sec)



# creation du fichier de compte
cat >/var/lib/mysql/extra <<EOF
[client]
user=root
password=$DB_password
EOF



# create base et populate
mysql  --defaults-extra-file=/var/lib/mysql/extra  < /tmp/dump.sql
#mysql -u root -p
#USE testdb;
#SHOW TABLES;
#select * from contenu_base_testdb;


# create user testuser and enable remote connection
sed -i '2 i\bind-address = 0.0.0.0' /etc/my.cnf
mysql --defaults-extra-file=/var/lib/mysql/extra -e "CREATE USER 'testuser'@'%' IDENTIFIED BY '$DB_password';"
mysql --defaults-extra-file=/var/lib/mysql/extra -e "GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';"
mysql --defaults-extra-file=/var/lib/mysql/extra -e "FLUSH PRIVILEGES;"



systemctl restart mariadb

