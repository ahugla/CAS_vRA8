#!/bin/bash 
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 9 Decembre 2019
# v1.9

# USAGE
# -----
# Necessite d'avoir dans le software component une property 'varTokenToJoin' de type 'String' mappé sur 'varTokenToJoin' de 'config master'.
# Ainsi qu'une property 'MasterNode' mappé sur l'ip du master
#
# fichierSRC=K8S-JoinCluster.sh
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/vRA/master/SoftwareComponents/Kubernetes-kubeadm/$fichierSRC
# chmod 755 $fichierSRC
# ./$fichierSRC $varTokenToJoin $MasterNode
# rm -f $fichierSRC


# Log $PATH
echo "Intial PATH = $PATH"

# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
echo "New PATH = $PATH"


#A FAIRE SUR LES NODES:  
# Necessite d'avoir dans le software component une property varTokenToJoin
varTokenToJoin=$1
echo "Token to join in 'K8S-JoinCluster.sh' : $varTokenToJoin"
MasterNode=$2
echo "MasterNode in 'K8S-JoinCluster.sh' : $MasterNode"
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
