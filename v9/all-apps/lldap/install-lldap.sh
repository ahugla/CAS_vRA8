/bin/bash
#
#     
#
#     Install light ldap (lldap) on docker
#     ------------------------------------
#     https://github.com/lldap/lldap?tab=readme-ov-file
#
#     usage :  Web interface sur port 17170 
#              compte "admin" / "password"
#     


# Set parameters
jwt_secret=VMware1!
ldap_user_pass=VMware1!


cd /tmp


# install git et wget
dnf install git wget -f


# clone lldap repo
git clone https://github.com/lldap/lldap.git


# update “jwt_secret” et “ldap_user_pass” dans /data/lldap_config.toml
mkdir /data
cp  lldap/lldap_config.docker_template.toml      /data/lldap_config.toml
# If the lldap_config.toml doesn't exist when starting up, LLDAP will use default one. 
# The default admin password is password, you can change the password later using the web interface.


# get docker compose file
# fixe les variables d'env notamment pour 'jwt_secret' et 'ldap_user_pass'
wget https://raw.githubusercontent.com/ahugla/CAS_vRA8/refs/heads/master/v9/all-apps/lldap/docker-compose.yaml.txt --no-check-certificate


# start lldap container
docker compose up --detach