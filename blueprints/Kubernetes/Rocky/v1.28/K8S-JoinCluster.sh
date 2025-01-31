#!/bin/bash 
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 11 Nov 2024
# OS : Rocky Linux
# Kubernetes : v1.28.
# file version : v2.0


# USAGE
# -----
#
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/Rocky/v1.28/K8S-JoinCluster.sh
# chmod 755 K8S-JoinCluster.sh
# ./$K8S-JoinCluster.sh  $MasterNode  $MasterPassword  $LIserver  $versionLI
# ex : ./K8S-JoinCluster.sh  172.19.5.4  my_pass!  vrli.cpod-vrealizesuite.az-demo.shwrfr.com  v8.4.0
# rm -f K8S-JoinCluster.sh


cd /tmp



# LOGGING DANS /tmp/K8S_INSTALL.LOG
# ----------------------------------
echo "Phase K8S-JoinCluster debut"  >> /tmp/K8S_INSTALL.LOG


# Set and display paramaters
MasterNode=$1
MasterPassword=$2
LIserver=$3
versionLI=$4
#MasterNode=172.17.1.61
#MasterPassword=changeme
#LIserver=vrli.cpod-vrealizesuite.az-demo.shwrfr.com
#versionLI=v8.4.0
echo "MasterNode in 'K8S-JoinCluster.sh' : $MasterNode"  >> /tmp/K8S_INSTALL.LOG
echo "LIserver : $LIserver"    >> /tmp/K8S_INSTALL.LOG
echo "versionLI : $versionLI"  >> /tmp/K8S_INSTALL.LOG


# Log $PATH
echo "Intial PATH = $PATH"

# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
echo "New PATH = $PATH"

#install sshpass
yum install -y sshpass

# On attend que le Master soit pret (c est a dire qu'il existe un fichier /tmp/k8stoken sur le master)
isMasterReady=`sshpass -p $MasterPassword ssh -o StrictHostKeyChecking=no root@$MasterNode 'ls /tmp' | grep k8stoken | wc -l`
echo "isMasterReady = $isMasterReady"
while [[ "$isMasterReady" -ne 1 ]]; do
  sleep 5
  isMasterReady=`sshpass -p $MasterPassword ssh -o StrictHostKeyChecking=no root@$MasterNode 'ls /tmp' | grep k8stoken | wc -l`
  echo "isMasterReady = $isMasterReady"
done
echo "Master ready to be joined" >> /tmp/K8S_INSTALL.LOG


# On  recupere le Token dans le fichier /tmp/k8stoken sur le master
varTokenToJoin=`sshpass -p $MasterPassword ssh -o StrictHostKeyChecking=no root@$MasterNode 'cat /tmp/k8stoken'`
echo "varTokenToJoin = $varTokenToJoin"


# Eviter le message d'erreur lors de kubeadm join :  [ERROR CRI]: container runtime is not running   
#rm -f /etc/containerd/config.toml
#systemctl enable containerd
#systemctl restart containerd


#A FAIRE SUR LES NODES:  
echo "kubeadm join starting ..." >> /tmp/K8S_INSTALL.LOG
# Necessite d'avoir dans le software component une property varTokenToJoin
kubeadm join $MasterNode:6443 --discovery-token-unsafe-skip-ca-verification --token $varTokenToJoin
# CA PREND 20 s pour apparaitre 
# In case the token to join has expired, create a new token:
# On Master, list the existing tokens:
#  kubeadm token list
# On Master, if there are no valid tokens, create a new token and list it:
#   kubeadm token create
#   kubeadm token list
# Join additional nodes in the cluster with the newly created token, e.g.,:
#   kubeadm join 172.16.1.125:6443 --discovery-token-unsafe-skip-ca-verification --token 5d4164.15b01d9af2e64824




# Installation et configuration de Log Insight
# --------------------------------------------
echo "install vRLI Agent" >> /tmp/K8S_INSTALL.LOG
# Installation de l'agent Log Insight
cd /tmp
git clone https://github.com/ahugla/LogInsight.git  /tmp/li
rpmLI=`ls /tmp/li/$versionLI/*.rpm`
rpm -iv $rpmLI


# config agent hostname + no ssl
#-------------------------------
liconfig=/var/lib/loginsight-agent/liagent.ini
# suppression de toutes les lignes contenant hostname=
sed -i '/hostname=/d' $liconfig
# ajout de la conf server apres la ligne [server]
ligne1="hostname=$LIserver"
sed -i '/\[server\]/a '$ligne1'' $liconfig
#suppression de toutes les lignes contenant ssl=yes
sed -i '/ssl=yes/d' $liconfig
# ajout de la conf ssl apres 'SSL usage'
sed -i '/SSL usage/a ssl=no' $liconfig

# restart et reboot persistence
systemctl restart liagentd
systemctl enable liagentd

# reste a aller sur le serveur LI et l'associer avec l'agent linux.
echo "LOG INSIGHT : reste a aller sur le serveur LI et l'associer avec l'agent linux."







