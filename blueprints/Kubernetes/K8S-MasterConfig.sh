#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 9 Decembre 2019
# v1.9

# USAGE
# -----
# Necessite d'avoir dans le software component une property 'varTokenToJoin' de type 'Computed'.
# 
# fichierSRC=K8S-MasterConfig.sh
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/vRA/master/SoftwareComponents/Kubernetes-kubeadm/$fichierSRC
# chmod 755 $fichierSRC
# ./$fichierSRC
# rm -f $fichierSRC
# varTokenToJoin=`cat /tmp/k8stoken`
#

# Log pour Debugging
echo "Shell utilise: $0"
echo "parametre1: $1"
echo "parametre2: $2"
echo "parametre3: $3"
echo "parametre4: $4"
echo "parametre5: $5"

# Log $PATH
echo "Initial PATH = $PATH"

# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
echo "New PATH = $PATH"


# Validate the ip-address:
echo "CHECK: hostname --ip-address"
hostname --ip-address

# Initialize Kubernetes master : https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname --ip-address) --token-ttl 0 #--ignore-preflight-errors=NumCPU

# The kubeadm command will take a few minutes and it will print a 'kubeadm join'
# command once completed. Make sure to capture and store this 'kubeadm join'
# command as it is required to add other nodes to the Kubernetes cluster.
# --token-ttl 0 permet de faire que le token du bootstrap n'expire jamais (on 
# peut tj faire des add nodes sans avoir a recreer un token)

# EXEMPLE D'OUTPUT:
# Your Kubernetes master has initialized successfully!
# To start using your cluster, you need to run the following as a regular user:
#    mkdir -p $HOME/.kube
#    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#    sudo chown $(id -u):$(id -g) $HOME/.kube/config
# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/
# You can now join any number of machines by running the following on each node as root:
# kubeadm join 172.18.4.155:6443 --token 0aq3yj.1nbjbntmhxajnmte --discovery-token-ca-cert-hash sha256:71a4a3c5dc0fec1230dbdbb3a95d7a83763e91331911d3aa55d9b06e19d73d00
#


# Log du process
# echo PROCESS=`ps -p $$`


# start  your cluster
# Attention : $HOME n'existe pas (shell application director)  =>   indispensable
echo "Initial HOME = $HOME"
export HOME=/root
echo "New HOME = $HOME"

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# Install Flannel for network
# Doc: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
kubectl apply -f  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Validate all pods are running
echo "CHECK PODS STATUS (Must be running)"
kubectl get pods --all-namespaces
# EXEMPLE D'OUTPUT:
# [root@vRA-VM-0878 ~]# kubectl get pods --all-namespaces
# kube-system   coredns-86c58d9df4-dxzfz              1/1     Running   0          3m23s
# kube-system   coredns-86c58d9df4-hjzjv              1/1     Running   0          3m23s
# kube-system   etcd-vra-vm-0878                      1/1     Running   0          2m17s
# kube-system   kube-apiserver-vra-vm-0878            1/1     Running   0          2m31s
# kube-system   kube-controller-manager-vra-vm-0878   1/1     Running   0          2m18s
# kube-system   kube-flannel-ds-amd64-h5s48           1/1     Running   0          87s
# kube-system   kube-proxy-trfcx                      1/1     Running   0          87s
# kube-system   kube-scheduler-vra-vm-0878            1/1     Running   0          2m24s


# ATTENDRE QUE TOUT SOIT UP :  on considere qu'il y a 10 pods a demarrer
sleep 5
nbRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
echo "nbRunning = $nbRunning"
while [[ "$nbRunning" -lt "8" ]]; do
	sleep 5
	nbRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
	echo "nbRunning = $nbRunning"
done
echo "Kubernetes Master is ready"


# on recupere le token necessaire pour que les nodes puissent rejoindre
# Necessite d'avoir dans le software component une property varTokenToJoin de type Computed
varTokenToJoin=`kubeadm token list | grep token | awk '{print $1}'`
echo "varTokenToJoin in 'K8S-MasterConfig.sh' = $varTokenToJoin"
rm -f /tmp/k8stoken
echo $varTokenToJoin > /tmp/k8stoken


# creation de l'alias 'kk'
echo "alias kk='kubectl'" >> /root/.bash_profile

