#!/bin/bash


# Parameters
# ---------
dbadminPassword=$1


#dnf module list redis
dnf -y install redis

systemctl enable --now redis

# Enable Redis Service to listen on all interfaces - By default, Redis service listens on 127.0.0.1.
ss -tunelp | grep 6379

# Accepter les connections remotes
# Pour voir la config en masquant les commentaires:    grep ^[^#]  /etc/redis.conf
# OLD : sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g'  /etc/redis.conf    
# default :  bind 127.0.0.1 -::1 
sed -i -e 's/bind 127.0.0.1 -::1/bind * -::*/g'  /etc/redis/redis.conf


systemctl  restart redis
systemctl status redis


#redis-cli 
#127.0.0.1:6379> ping
#PONG



# creation du requirepass
mypass=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 10`
echo "requirepass $mypass"   >> /etc/redis/redis.conf



# creation de l'ACL d'admin 
#  +@all : in tous les droits
#  ~*    : pour tous les objets
echo "user dbadmin on +@all ~*  >$dbadminPassword"  >> /etc/redis/redis.conf


systemctl restart redis