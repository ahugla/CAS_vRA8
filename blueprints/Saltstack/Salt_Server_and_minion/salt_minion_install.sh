#!/bin/bash 

# ALEX H.
# 13 Janvier 2021
# v1.0

# USAGE
# -----
#
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/K8S-JoinCluster.sh
# chmod 755 K8S-JoinCluster.sh
# ./$K8S-JoinCluster.sh  $MasterNode  $MasterPassword  $LIserver  $versionLI
# ex : ./K8S-JoinCluster.sh  172.19.5.4  my_pass!  vrli.cpod-vrealizesuite.az-demo.shwrfr.com  v8.1.0
# rm -f K8S-JoinCluster.sh





Install python3
---------------
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




Install last release of salt minion
-----------------------------------
cd /tmp
yum install -y https://repo.saltstack.com/py3/redhat/salt-py3-repo-latest.el7.noarch.rpm
yum clean expire-cache
yum install -y salt-minion   # salt-ssh   salt-master ...

# set master:
MASTER_IP=192.168.192.350
sed -i -e 's/#master: salt/master: '"$MASTER_IP"'/g'  /etc/salt/minion

systemctl enable salt-minion
systemctl start salt-minion

# if upgrade:   ystemctl restart salt-minion



