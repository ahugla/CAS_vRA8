/bin/bash
#
#     
#
#     Install light ldap (lldap) on docker
#     ------------------------------------
#     https://github.com/lldap/lldap?tab=readme-ov-file
#
#     usage :  Web interface sur port 17170 
#              compte "admin"
#     


# Set parameters
jwt_secret=VMware1!
ldap_user_pass=VMware1!


cd /


# install git et wget
dnf install git wget -f


# clone lldap repo
git clone https://github.com/lldap/lldap.git


# update “jwt_secret” et “ldap_user_pass” dans /data/lldap_config.toml


# get docker compose file
wget https://raw.githubusercontent.com/ahugla/CAS_vRA8/refs/heads/master/v9/all-apps/lldap/docker-compose.yaml.txt


# start lldap container
docker compose up --detach