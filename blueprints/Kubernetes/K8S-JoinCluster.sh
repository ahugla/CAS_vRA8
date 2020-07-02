#!/bin/bash 
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 30 Juin 2020
# v1.10

# USAGE
# -----
#
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/K8S-JoinCluster.sh
# chmod 755 $fichierSRC
# ./$fichierSRC  $MasterNode  $MasterPassword
# rm -f $fichierSRC

# Set and display paramaters
MasterNode=$1
MasterPassword=$2
echo "MasterNode in 'K8S-JoinCluster.sh' : $MasterNode"

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

# On  recupere le Token dans le fichier /tmp/k8stoken sur le master
varTokenToJoin=`sshpass -p $MasterPassword ssh -o StrictHostKeyChecking=no root@$MasterNode 'cat /tmp/k8stoken'`
echo "varTokenToJoin = $varTokenToJoin"


#A FAIRE SUR LES NODES:  
# Necessite d'avoir dans le software component une property varTokenToJoin
kubeadm join $MasterNode:6443 --discovery-token-unsafe-skip-ca-verification --token $varTokenToJoin



# FIN
#  c est a ce moment qu'on fait la commande "kubeadm join" sur les nodes : CA PREND 20 s pour apparaitre 
# In case the token to join has expired, create a new token:
# On Master, list the existing tokens:
#  kubeadm token list
# On Master, if there are no valid tokens, create a new token and list it:
#   kubeadm token create
#   kubeadm token list
# Join additional nodes in the cluster with the newly created token, e.g.,:
#   kubeadm join 172.16.1.125:6443 --discovery-token-unsafe-skip-ca-verification --token 5d4164.15b01d9af2e64824
