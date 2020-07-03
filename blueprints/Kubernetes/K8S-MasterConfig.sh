#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 30 Juin 2020
# v1.10

# USAGE
# -----
# 
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/K8S-MasterConfig.sh
# chmod 755 $fichierSRC
# ./$fichierSRC $LB_IPrange
# rm -f $fichierSRC
#

# display input parameters
LB_IPrange=$1
echo "LB_IPrange = $LB_IPrange"

# Log $PATH
echo "Initial PATH = $PATH"

# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
echo "New PATH = $PATH"

# Validate the ip-address:
echo "CHECK: hostname --ip-address"
hostname --ip-address


# Prerequis à l'init
ip_forward=`cat /proc/sys/net/ipv4/ip_forward`
echo "Avant : ip_forward = $ip_forward"
sysctl net.ipv4.ip_forward=1 
ip_forward=`cat /proc/sys/net/ipv4/ip_forward`
echo "Apres : ip_forward = $ip_forward"


# Initialize Kubernetes master : https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
# "init" verifie des pre-requis (comme le nombre de cpu) et cree le fichier de config de kubelet: /var/lib/kubelet/config.yaml
echo "kubeadm init ... starting ..."
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname --ip-address) --token-ttl 0 #--ignore-preflight-errors=NumCPU

# The kubeadm command will take a few minutes and it will print a 'kubeadm join'
# command once completed. Make sure to capture and store this 'kubeadm join'
# command as it is required to add other nodes to the Kubernetes cluster.
# --token-ttl 0 permet de faire que le token du bootstrap n'expire jamais (on 
# peut tj faire des add nodes sans avoir a recreer un token)

# EXEMPLE D'OUTPUT:
# Your Kubernetes control-plane has initialized successfully!
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


# start the cluster (On a remplacé $HOME par /root)
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown $(id -u):$(id -g) /root/.kube/config


env
whoami

echo "WAIT 30 Sec"
sleep 30

echo "etat kubelet"
systemctl status kubelet
echo "test access aux pods"
kubectl get pods --all-namespaces 


# MUST wait for K8S to start
# errormsg : The connection to the server localhost:8080 was refused: 
#kubectl get pods --all-namespaces 
#isRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
#while [ $isRunning -lt 1 ]
#do
#	echo "On attend 2s que Kubernetes demarre ..."
#	sleep 2
#	kubectl get pods --all-namespaces
#	isRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
#done



# Install Flannel for network
# Doc: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
echo "APPLY FLANNEL - DEBUT"
kubectl apply -f  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
echo "APPLY FLANNEL - FIN"


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


# ATTENDRE QUE TOUT SOIT UP :  il y a 8 pods a demarrer, mais on attend que tous les pods soient up
sleep 5  #  sinon aucun pods n'a le temps de se creer
nbRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
nbLigne=`kubectl get pods --all-namespaces | wc -l`
nbTarget=`echo $(($nbLigne-1))`
echo "nbRunning = $nbRunning sur $nbTarget"
while [ $nbRunning -lt $nbTarget ] || [ $nbRunning -eq 0 ]
do
	sleep 5
	nbRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
	nbLigne=`kubectl get pods --all-namespaces | wc -l`
	nbTarget=`echo $(($nbLigne-1))`
	echo "nbRunning = $nbRunning sur $nbTarget"
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



# MetalLB install and config in Layer 2 Mode
#-------------------------------------------
echo "Creation du LB metalLB (en mode Layer 2) dans le namespace metallb-system"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml    # create metallb-system namespace
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml      # deploy MetalLB

# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
# The components in the manifest are:
# The metallb-system/controller deployment. This is the cluster-wide controller that handles IP address assignments.
# The metallb-system/speaker daemonset. This is the component that speaks the protocol(s) of your choice to make the services reachable.
# Service accounts for the controller and speaker, along with the RBAC permissions that the components need to function.
# The installation manifest does not include a configuration file. MetalLB’s components will still start, but will remain idle until 
# you define and deploy a configmap. 
# The memberlist secret contains the secretkey to encrypt the communication between speakers for the fast dead node detection.

# create config file (ConfigMap)
cat <<EOF > /tmp/metalLBconfig.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
      - name: my-ip-space
        protocol: layer2
        addresses:
          - $LB_IPrange
EOF

kubectl apply -f /tmp/metalLBconfig.yaml

