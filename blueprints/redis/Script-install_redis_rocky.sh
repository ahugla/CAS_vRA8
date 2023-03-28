#!/bin/bash


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






























# Load Redis environment variables
. /opt/bitnami/scripts/redis-env.sh

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libredis.sh


print_welcome_page

if [[ "$*" = *"/opt/bitnami/scripts/redis/run.sh"* || "$*" = *"/run.sh"* ]]; then
    info "** Starting Redis setup **"
    /opt/bitnami/scripts/redis/setup.sh
    info "** Redis setup finished! **"
fi

echo ""
exec "$@"




grep -rnl /* -e 'Cats'
	/bitnami/redis/data/appendonly.aof
	/bitnami/redis/data/dump.rdb





