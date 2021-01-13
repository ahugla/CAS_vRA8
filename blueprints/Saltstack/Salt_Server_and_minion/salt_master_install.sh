#!/bin/bash 

# ALEX H.
# 13 Janvier 2021
# v1.0

# USAGE
# -----
#
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Saltstack/Salt_Server_and_minion/salt_master_install.sh
# chmod 755 salt_master_install.sh
# ./salt_master_install.sh
# rm -f salt_master_install.sh



# Install python3
# ---------------
cd /tmp

# need to have an EPEL repo if not the case
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh epel-release-latest-7*.rpm
rm -f /tmp/epel-release-latest-7.noarch.rpm

# install python3
yum install -y python3    #  =>  installe python 3.6alias python='/usr/bin/python3'

# set python3 as default
alias python='/usr/bin/python3'
echo "# config python3 (ALEX)"  >> /root/.bashrc 
echo "alias python='/usr/bin/python3'"  >> /root/.bashrc 
. ~/.bashrc   # recharge .bashrc

# verification
python --version   




# Install last release of salt Master
# -----------------------------------
cd /tmp
yum install -y https://repo.saltstack.com/py3/redhat/salt-py3-repo-latest.el7.noarch.rpm
yum clean expire-cache
yum install -y salt-master   # salt-minion  salt-ssh ...
systemctl enable salt-master
systemctl start salt-master





