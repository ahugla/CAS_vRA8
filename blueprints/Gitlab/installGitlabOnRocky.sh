#!/bin/bash

#
# Install gitlab-ce on Rocky Linux
# 
# BASED on https://www.vultr.com/docs/how-to-install-gitlab-community-edition-ce-11-x-on-centos-7
# 


# Add a swap partition and tweak the swappiness setting
sudo dd if=/dev/zero of=/swapfile count=4096 bs=1M
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile   none    swap    sw    0   0' | sudo tee -a /etc/fstab
free -m

# for performance
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
cat /proc/sys/vm/swappiness



# Install the EPEL YUM repo and then update the system
sudo dnf install -y epel-release
#sudo dnf -y update && sudo shutdown -r now          # ===>>>>   REBOOT


# Install required dependencies
sudo dnf install -y curl policycoreutils-python-utils openssh-server openssh-clients



# Setup the GitLab CE RPM repository on your system:
cd /tmp
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash



# Install GitLab CE 
#external_url="http://[VRA_VM].cpod-vrealize.az-fkd.cloud-garage.net"
#external_url="http://`hostname`.cpod-vrealize.az-fkd.cloud-garage.net"
EXTERNAL_URL="http://`hostname`.cpod-vrealize.az-fkd.cloud-garage.net" dnf install -y gitlab-ce



echo "Install GitLab CE Terminée"
echo "Connect using : " $EXTERNAL_URL
echo "root password in /etc/gitlab/initial_root_password (dure 24h)"


# POUR SE CONNECTER :   http://[VRA_VM].cpod-vrealize.az-fkd.cloud-garage.net
# login : root
# password :  dans /etc/gitlab/initial_root_password   (disparait apres 24h)


#
# Si ca ne fonctionne pas, ouvrir   vi /etc/gitlab/gitlab.rb  et remplacer external_url par la valeur.
# puis faire "gitlab-ctl reconfigure"

