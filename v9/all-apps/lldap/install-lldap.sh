/bin/bash
#
#
#
#     install light ldap (lldap)
#
#     usage :  Web interface sur port 17170 
#              compte "admin"
#     


# Set parameters
jwt_secret=VMware1!
ldap_user_pass=VMware1!


cd /tmp


# install git
dnf install git -f


# clone lldap repo
git clone https://github.com/lldap/lldap.git


# update “jwt_secret” et “ldap_user_pass” dans /data/lldap_config.toml


# get docker compose file


# start lldap container
docker compose up --detach