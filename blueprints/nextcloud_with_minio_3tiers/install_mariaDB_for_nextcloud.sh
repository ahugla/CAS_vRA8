#   INSTALLATION DE mariaDB sur Rocky Linux
#
#  v1.0
#
#  Alexandre Hugla
#  16/01/2024
#
#
#  USAGE :  install_mariaDB.sh   [DB_root_password]  [DB_nextcloud_user_password] 
#



# Recuperation des variables
DB_root_password=$1   	           # password du compte de root de la DB
DB_nextcloud_user_password=$2      # password du compte de service 'nextcloud-user' qu'utilise nextcloud


cd /tmp/


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


# Enable remote connection
sed -i -e '/bind-address/s/^#//' /etc/my.cnf.d/mariadb-server.cnf     # enleve le signe de commentaire en debut de ligne


systemctl restart mariadb

