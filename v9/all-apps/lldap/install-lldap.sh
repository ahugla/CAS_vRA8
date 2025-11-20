/bin/bash
#
#     
#
#     Install light ldap (lldap) on docker
#     ------------------------------------
#     https://github.com/lldap/lldap?tab=readme-ov-file
#
#     usage: ./install-lldap.sh [adminPassword]
#
#     Web access :  Web interface sur port 17170 
#                   compte "admin" / "default password"
#     


# Set parameters
#jwt_secret=KKKKKK
ldap_user_pass=$1   # adminPassword,  password for the 'admin' account on the web interface


cd /tmp


# install git et wget
dnf install git wget -y


# clone lldap repo
git clone https://github.com/lldap/lldap.git


# Copie du fichier de config
mkdir /data
cp  lldap/lldap_config.docker_template.toml      /data/lldap_config.toml
# If the lldap_config.toml doesn't exist when starting up, LLDAP will use default one. 
# On peut mettre en dur les variables 'jwt_secret' et 'ldap_user_pass'.
# Ici, on n'utilise pas le fichier de config pour updater le token jwt_secret et le password admin (on le fait plus tard par variable d'env)


# get docker compose file
cd /data
wget https://raw.githubusercontent.com/ahugla/CAS_vRA8/refs/heads/master/v9/all-apps/lldap/docker-compose.yaml --no-check-certificate


# update “ldap_user_pass” (adminPassword) dans /data/lldap_config.toml
# On passe par les variables d'environnement du docker compose file pour communiquer le password
sed -i -e 's/AAAAAAAA/'"$ldap_user_pass"'/g'   /data/docker-compose.yaml


# start lldap container
docker compose up --detach


# pause le temps que le container demarre
sleep 10


# restore lldap data from backup
# si y a pas le users.db,  il repart comme si c etait une fresh install
# il faut que le container ait demarré une fois pour creer le path "/var/lib/docker/volumes/data_lldap_data/_data/"
docker stop $(docker ps -aqf "name=data-lldap-1")
rm -f /var/lib/docker/volumes/data_lldap_data/_data/users.db
cp /tmp/myBackup /var/lib/docker/volumes/data_lldap_data/_data/users.db  
chown cloud-user:cloud-user  /var/lib/docker/volumes/data_lldap_data/_data/users.db  
docker start $(docker ps -aqf "name=data-lldap-1")



