#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 16 Juin 2021
# v1.5

# USAGE
# -----
# 
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/K8S-MasterConfig.sh
# chmod 755 K8S-MasterConfig.sh
# ./K8S-MasterConfig.sh $LB_IPrange  $cadvisor_version $k8s_cluter_name      # ex : ./K8S-MasterConfig.sh  172.17.1.226-172.17.1.239   v0.34.0   k8s_alex
# rm -f K8S-MasterConfig.sh
#


cd /tmp


# display input parameters
LB_IPrange=$1         #LB_IPrange=172.17.1.236-172.17.1.239
cadvisor_version=$2   #cadvisor_version=v0.34.0
k8s_cluter_name=$3    #k8s_cluter_name=alex-k8s
echo "LB_IPrange = $LB_IPrange"
echo "cadvisor_version = $cadvisor_version"
echo "k8s_cluter_name = $k8s_cluter_name"

# recuperer la version de Kubernetes
K8S_VERSION_WITHv=`kubelet --version | awk '{print $2}'`
K8S_VERSION=`echo ${K8S_VERSION_WITHv:1:20}`
echo "K8S_VERSION = $K8S_VERSION"

# get and check the ip-address:
# "hostname --ip-address" peut donner "172.17.1.54" ou "::1 172.17.1.54"  =>  on prefere la commande "hostname -I | awk '{print $1}'"
echo "CHECK: hostname --ip-address"
hostname -I | awk '{print $1}'
var_myIP=`hostname -I | awk '{print $1}'`



#set $HOME   INDISPENSABLE CAR UTILISATION DE LA COMMANDE kubectl
echo "avant HOME = $HOME"
HOME=/root
export HOME=$HOME
echo "apres HOME = $HOME"

# Log $PATH
echo "PATH = $PATH"
# initial PATH  /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin




# kubeadm avec config file et policy de logging
# ---------------------------------------------
curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/kubeadm_config_file_template.yaml
mv kubeadm_config_file_template.yaml kubeadm_config_file.yaml 

# update du fichier de config:
sed -i -e 's/A.B.C.D/'$var_myIP'/g'  /tmp/kubeadm_config_file.yaml   #  on met l'IP du master
sed -i -e 's/K8S_VERSION/'$K8S_VERSION'/g'  /tmp/kubeadm_config_file.yaml   #  on indique la version de kubernetes a installer (la meme que kubeadm; kubectl et kubelet)
sed -i -e 's/k8s_cluter_name/'$k8s_cluter_name'/g'  /tmp/kubeadm_config_file.yaml   #  on met le nom du cluster K8S

# creation des repertoires pour les logs et pour le fichier de config des logs
mkdir /var/log/kubernetes
mkdir /var/log/kubernetes/apiserver
mkdir /etc/kubernetes/audit-policies

# Creation de la policy de logging
cat > /etc/kubernetes/audit-policies/policy.yaml << EOF  
# Log all requests at the Metadata level.
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF

# EXEMPLE D'UN FICHIER DE CONFIG POUR KUBEADM INIT:
# apiVersion: kubeadm.k8s.io/v1beta2
# kind: InitConfiguration
# localAPIEndpoint:
#   advertiseAddress: 172.17.1.74
#   bindPort: 6443
# apiServer:
#   extraArgs:
#     audit-policy-file: /k8s-policy/policy.yaml
#     audit-log-path: /k8s-logs/apiserver/audit.log
#   extraVolumes:
#   - name: "policy-conf"
#     hostPath: "/etc/kubernetes/audit-policies/"
#     mountPath: "/k8s-policy/"
#     pathType: DirectoryOrCreate
#   - name: "apiserver-log"
#     hostPath: "/var/log/kubernetes/apiserver/"
#     mountPath: "/k8s-logs/apiserver/"
#     pathType: DirectoryOrCreate
#   timeoutForControlPlane: 4m0s
# kind: ClusterConfiguration
# kubernetesVersion: 1.21.1
# clusterName: kubernetes
# networking:
#   dnsDomain: cluster.local
#   podSubnet: 10.244.0.0/16
#   serviceSubnet: 10.96.0.0/12
# scheduler: {}



# OLD : kubeadm en command line (sans config de log pour l audit)
# ---------------------------------------------------------------
# Initialize Kubernetes master : https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
# "init" verifie des pre-requis (comme le nombre de cpu) et cree le fichier de config de kubelet: /var/lib/kubelet/config.yaml
#echo "kubeadm init ... starting ..."
#kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $1}') --token-ttl 0 #--ignore-preflight-errors=NumCPU
# The kubeadm command will take a few minutes and it will print a 'kubeadm join'
# command once completed. Make sure to capture and store this 'kubeadm join'
# command as it is required to add other nodes to the Kubernetes cluster.
# --token-ttl 0 permet de faire que le token du bootstrap n'expire jamais (on 
# peut tj faire des add nodes sans avoir a recreer un token)



# init du cluster
echo "kubeadm init ... starting ..."
kubeadm init --config /tmp/kubeadm_config_file.yaml


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


# start the cluster 
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# MUST wait for K8S to start (on attend un running au moins) 
# Si pas de $HOME=/root  alors  errormsg : The connection to the server localhost:8080 was refused
isRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
while [ $isRunning -lt 1 ]
do
	echo "On attend 2s que Kubernetes demarre ..."
	sleep 2
	kubectl get pods --all-namespaces
	isRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
done
# EXEMPLE D'OUTPUT:
# [root@vRA-VM-0878 ~]# kubectl get pods --all-namespaces
# kube-system   coredns-86c58d9df4-dxzfz              0/1     Pending   0     => demarrera apres l'install de flannel
# kube-system   coredns-86c58d9df4-hjzjv              0/1     Pending   0     => demarrera apres l'install de flannel
# kube-system   etcd-vra-vm-0878                      1/1     Running   0
# kube-system   kube-apiserver-vra-vm-0878            1/1     Running   0
# kube-system   kube-controller-manager-vra-vm-0878   1/1     Running   0
# kube-system   kube-proxy-trfcx                      1/1     Running   0
# kube-system   kube-scheduler-vra-vm-0878            1/1     Running   0




# Install Flannel for network
# Doc: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
kubectl apply -f  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


# ATTENDRE QUE TOUT SOIT UP :  il y a 8 pods a demarrer, mais on attend que tous les pods soient up
# Si pas de $HOME=/root  alors  errormsg : The connection to the server localhost:8080 was refused
nbRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
nbLigne=`kubectl get pods --all-namespaces | wc -l`
nbTarget=`echo $(($nbLigne-1))`
echo "nbRunning = $nbRunning sur $nbTarget"
while [ $nbRunning -lt $nbTarget ] || [ $nbRunning -eq 0 ]
do
	echo "nbRunning = $nbRunning sur $nbTarget"
	sleep 2
	nbRunning=`kubectl get pods --all-namespaces | grep Running | wc -l`
	nbLigne=`kubectl get pods --all-namespaces | wc -l`
	nbTarget=`echo $(($nbLigne-1))`
done
echo "Kubernetes Master is ready"
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


# on recupere le token necessaire pour que les nodes puissent rejoindre
# Necessite d'avoir dans le software component une property varTokenToJoin de type Computed
varTokenToJoin=`kubeadm token list | grep token | awk '{print $1}'`
echo "varTokenToJoin in 'K8S-MasterConfig.sh' = $varTokenToJoin"
rm -f /tmp/k8stoken
# indique aux nodes que le master et pret et qu'ils peuvent s'y raccrocher
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

# Role 'controller' de MetalLB reste pending tant qu'il n'y a pas au moins un node raccroché au cluster

    

# Installe le Dashboard Kubernetes et configure l'acces pour le namespace default
# cadvisor est embedded dans kubelet pour les besoins du core pipeline (pas pour monitoring externe)
# Dashboard Kubernetes a besoin de metrics-server (Heapster is deprecated)
# --------------------------------------------------------------------------------------------------
#deploiement sur le master (sinon pb)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended.yaml

# creation du service de type LoadBalancer
kubectl expose deployment kubernetes-dashboard --type=LoadBalancer --name=service-dashboard -n kubernetes-dashboard
# Il faut que les pods metalLB soit up  =>  au moins un worker node
# Peut prendre quelques minutes pour etre indiqué avec 'get service' =>  si <pending> refaire apres un petit moment

# On donne tous les droits au compte par default 'default'
kubectl create clusterrolebinding fullrightstodefault \
  --clusterrole=cluster-admin \
  --serviceaccount=default:default

# On attend que le service dashboard recupere une IP externe (pour cela il faut un node de connecté)
dashboard_svc_ip=`kubectl get services -n kubernetes-dashboard | grep service-dashboard | awk '{print $4}'`
while [ "$dashboard_svc_ip" == "<pending>" ]
do
  echo "'service-dashboard' still <pending> ... waiting 2s ..."
  sleep 2
  dashboard_svc_ip=`kubectl get services -n kubernetes-dashboard | grep service-dashboard | awk '{print $4}'`
  echo "dashboard_svc_ip=$dashboard_svc_ip"
done

# Le Kubernetes Dashboard depend de metrics-server, il faut l'installer
# -L car redirection
curl -LO  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# comme on est dans un env de test, les certificates sont pas configurés, si on rajoute pas --kubelet-insecure-tls, le pod metrics-server ne demarre pas
sed -i '/kubelet-use-node-status-port/a \        - --kubelet-insecure-tls\' components.yaml
kubectl apply -f components.yaml
rm components.yaml

# Affichage de l'URL du Dashboard et du token
dashboard_svc_ip=`kubectl get services -n kubernetes-dashboard | grep service-dashboard | awk '{print $4}'`
dashboard_svc_port=`kubectl get services -n kubernetes-dashboard| grep service-dashboard | awk '{print $5}' | awk -F: '{print $1}'`
dashboard_token=`kubectl get secret $(kubectl get serviceaccount default -n default -o jsonpath="{.secrets[0].name}") -n default -o jsonpath="{.data.token}" | base64 --decode`
echo "-------------------------------------------------------------------------------------"
echo "                                                                                     "
echo "Access to Kubernetes Dashboard using:   https://$dashboard_svc_ip:$dashboard_svc_port"
echo "With token:                                                                          "
echo "$dashboard_token                                                                     "
echo "                                                                                     "
echo "-------------------------------------------------------------------------------------"
# Creation du fichier avec ces informations: 
echo "-------------------------------------------------------------------------------------" >  /tmp/K8S_Dashboard_Access.info
echo "                                                                                     " >> /tmp/K8S_Dashboard_Access.info
echo "Access to Kubernetes Dashboard using:   https://$dashboard_svc_ip:$dashboard_svc_port" >> /tmp/K8S_Dashboard_Access.info
echo "With token pour namespace 'default':                                                 " >> /tmp/K8S_Dashboard_Access.info
echo "$dashboard_token                                                                     " >> /tmp/K8S_Dashboard_Access.info
echo "                                                                                     " >> /tmp/K8S_Dashboard_Access.info
echo "-------------------------------------------------------------------------------------" >> /tmp/K8S_Dashboard_Access.info





# Installation d'un service monitoring pipeline à base de cadvisor daemonset
# Configuré pour vRops monitoring: hostPort: 31194
# L'image de cadvisor n'est plus sur dockerhub, mais desormais sur la registry google ici:  https://console.cloud.google.com/gcr/images/google-containers/GLOBAL/
# --------------------------------------------------------------------------

# clone des yaml de cadvisor
git clone https://github.com/google/cadvisor.git

# on remplace le daemonset de cadvisor par celui pour vRops
cd cadvisor/deploy/kubernetes/base
rm -f daemonset.yaml
curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/cadvisor_for_vRops_daemonset.yaml

# configuration  de la version de cadvisor
sed -i -e 's/{{cadvisor_version}}/'"$cadvisor_version"'/g'  cadvisor_for_vRops_daemonset.yaml

# deploiement
kubectl create -f .

rm -rf cadvisor





