#!/bin/bash


# ALEX H.
# 11 Nov 2024
# OS : Rocky Linux
# Kubernetes : v1.28.
# file version : v2.0



# USAGE
# -----
# 
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/Rocky/v1.28/K8S-MasterConfig.sh
# chmod 755 K8S-MasterConfig.sh
# ./K8S-MasterConfig.sh $LB_IPrange  $cadvisor_version $k8s_cluter_name $LIserver $versionLI    # ex : ./K8S-MasterConfig.sh  172.17.1.226-172.17.1.239   v0.34.0   k8s_alex  vrli.cpod-vrealizesuite.az-demo.shwrfr.com  v8.4.0
# rm -f K8S-MasterConfig.sh
#


# Install old version of K8S, get binaries:  https://flex-solution.com/page/blog/install-k8s-lower-than-1_24


# LOGGING DANS /tmp/K8S_INSTALL.LOG
# ----------------------------------
echo "Phase K8S-MasterConfig debut"  >> /tmp/K8S_INSTALL.LOG


cd /tmp


# set global parameters
kubeadm_config_file=kubeadm_config_file_template_1.28.yaml


# display input parameters
LB_IPrange=$1                               #LB_IPrange=172.17.1.236-172.17.1.239
cadvisor_version=$2                         #cadvisor_version=v0.34.0
k8s_cluter_name=$3                          #k8s_cluter_name=alex-k8s
LIserver=$4                                 #LIserver=vrli.cpod-vrealizesuite.az-demo.shwrfr.com
versionLI=$5                                #versionLI=v8.4.0
#LB_IPrange=172.17.1.237-172.17.1.239
#cadvisor_version=v0.34.0
#k8s_cluter_name=alex-k8s
#LIserver=vrli.cpod-vrealizesuite.az-demo.shwrfr.com
#versionLI=v8.4.0
echo "LB_IPrange = $LB_IPrange"
echo "cadvisor_version = $cadvisor_version"
echo "k8s_cluter_name = $k8s_cluter_name"
echo "kubeadm_config_file = $kubeadm_config_file"
echo "LIserver = $LIserver"
echo "versionLI = $versionLI"


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



# Rocky 8 uses "nftables" as the backend by default, whereas "Centos 7" uses iptables 
# Kubernetes supports "nftables" a partir de la v1.31, default is "iptables"
#
#   =>  pour K8S <  1.31 il faut installer iptables sur Rocky
#   =>  pour K8S >= 1.31 il faut configurer le fichier "kubeadm_config_file" en rajoutant :
#          apiVersion: kubeproxy.config.k8s.io/v1alpha1
#          kind: KubeProxyConfiguration
#          mode: nftables
#
# nftables commands (kubernetes >= 1.31)
# ------------------
#    nft list ruleset
#    systemctl status nftables
#
# Proxy modes (default: 'iptables mode' )
# https://kubernetes.io/docs/reference/networking/virtual-ips/
# -----------
# If you’re using kube-proxy in IPVS mode, since Kubernetes v1.14.2 you have to enable strict ARP mode
# check if IPVS is configured :  kubectl get configmap kube-proxy -n kube-system | grep mode
# Verify kube-proxy is started with ipvs proxier :   kubectl logs [kube-proxy pod] | grep "Using ipvs Proxier"
# Kill kubelet pour prendre en compte un changement :  kubectl get pod -n kube-system  puis  kubectl delete pod -n kube-system <pod-name>
# kubectl edit configmap -n kube-system kube-proxy
#     apiVersion: kubeproxy.config.k8s.io/v1alpha1
#     kind: KubeProxyConfiguration
#     mode: "ipvs"
#     ipvs:
#       strictARP: true



# Fichdier de config de kubeadm
# ------------------------------
curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/Rocky/v1.28/$kubeadm_config_file

# update du fichier de config:
sed -i -e 's/A.B.C.D/'$var_myIP'/g'  /tmp/$kubeadm_config_file                   #  on met l'IP du master
sed -i -e 's/K8S_VERSION/'$K8S_VERSION'/g'  /tmp/$kubeadm_config_file            #  on indique la version de kubernetes a installer (la meme que kubeadm; kubectl et kubelet)
sed -i -e 's/K8S_CLUSTER_NAME/'$k8s_cluter_name'/g'  /tmp/$kubeadm_config_file   #  on met le nom du cluster K8S

# EXEMPLE D'UN FICHIER DE CONFIG POUR KUBEADM INIT:
#apiVersion: kubeadm.k8s.io/v1beta3
#kind: InitConfiguration
#localAPIEndpoint:
#  advertiseAddress: 172.17.1.54                                  # advertiseAddress: 172.17.1.74
#  bindPort: 6443
#nodeRegistration:
#  imagePullPolicy: IfNotPresent
#  taints:
#  - effect: NoSchedule
#    key: node-role.kubernetes.io/master
#---
#apiVersion: kubeadm.k8s.io/v1beta3
#kind: ClusterConfiguration
#apiServer:
#  extraArgs:
#    audit-log-path: /k8s-logs/apiserver/audit.log
#    audit-policy-file: /k8s-policy/policy.yaml
#  extraVolumes:
#  - hostPath: /etc/kubernetes/audit-policies/
#    mountPath: /k8s-policy/
#    name: policy-conf
#    pathType: DirectoryOrCreate
#  - hostPath: /var/log/kubernetes/apiserver/
#    mountPath: /k8s-logs/apiserver/
#    name: apiserver-log
#    pathType: DirectoryOrCreate
#  timeoutForControlPlane: 4m0s
#certificatesDir: /etc/kubernetes/pki
#clusterName: alex-k8s                                # clusterName: k8s-alex
#controllerManager: {}
#dns: {}
#etcd:
#  local:
#    dataDir: /var/lib/etcd
#kubernetesVersion: 1.28.13                               # kubernetesVersion: v1.28.15
#networking:
#  dnsDomain: cluster.local
#  podSubnet: 10.244.0.0/16
#  serviceSubnet: 10.96.0.0/12
#scheduler: {}
#---
#apiVersion: kubeproxy.config.k8s.io/v1alpha1
#kind: KubeProxyConfiguration
#mode: iptables


# Policy de logging
# -----------------
# creation des repertoires pour les logs et pour le fichier de policy de log d'audit 
mkdir /var/log/kubernetes
mkdir /var/log/kubernetes/apiserver
mkdir /etc/kubernetes/audit-policies

# Creation de la policy de logging
# Log verbs 'create' and 'delete' at the 'Metadata' level.
curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/Rocky/v1.28/audit_policy.yaml
mv audit_policy.yaml /etc/kubernetes/audit-policies/policy.yaml 



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



# INUTILE pull des imges containers
# sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm. It is recommended that using "registry.k8s.io/pause:3.9" as the CRI sandbox image
# kubeadm config images pull



# init du cluster
echo "kubeadm init ... starting ..."
kubeadm init --config /tmp/$kubeadm_config_file



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
echo "Demarrage du cluster ..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config    # admin.conf est créé par "kubeadm init".
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# MUST wait for K8S to start (on attend un running au moins) 
echo "Wait for K8S to start ..."
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




# Retrait du taint sur le mgmt node:
# By default, your cluster will not schedule Pods on the control plane nodes for security reasons
# Voir le Taint d'un node:  kubectl describe node vra-009612 | grep  Taint     #  =>  node-role.kubernetes.io/master:NoSchedule
# On retire le taint pour pouvoir scheduler sur le control plane
# Le '-' a la fin de la ligne est pour enlever le taint
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-




# Install Flannel for network
# Doc: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#before-you-begin
# https://github.com/flannel-io/flannel#deploying-flannel-manually
echo "Install de Flannel ..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# old: kubectl apply -f  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml



# ATTENDRE QUE TOUT SOIT UP :  il y a 8 pods a demarrer, mais on attend que tous les pods soient up
# Si pas de $HOME=/root  alors  errormsg : The connection to the server localhost:8080 was refused
echo "On attend que les pods soient running (8) ..."
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
# see:    https://metallb.universe.tf/installation/   
#
# install metallb
echo "Install de metallb ..."
# metallb.io v1beta1 AddressPool is deprecated, consider using IPAddressPool  =>     passer en 0.14.8
# OR v0.14.8 : NO OK : ne fonctionne pas ...
# wget https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
wget https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
# Pour eviter pb avec IPAddressPool qui ne se cree pas ensuite:
sed -i -e 's/failurePolicy: Fail/failurePolicy: Ignore/g'  metallb-native.yaml 
kubectl apply -f metallb-native.yaml
# rm -f metallb-native.yaml


# On attend que metallb soit demarré avant de le configurer
echo "on attend que metallb soit demarré avant de le configurer ..."
# on attend que les premiers pods existent avant de les compter
nb_metallb=`kubectl get pods -n metallb-system | grep / | wc -l` 
while [ "$nb_metallb" = "0" ]
do
  echo "Pas de pod metallb encore, on attend 2s ..."
  sleep 2
  nb_metallb=`kubectl get pods -n metallb-system | grep / | wc -l` 
done
# y a des pods metallb, on attends qu'ils soient Running
nb_metallb_running=`kubectl get pods -n metallb-system | grep Running | grep / | wc -l` 
echo " metallb: $nb_metallb_running / $nb_metallb"
while [ "$nb_metallb_running" != "$nb_metallb" ]
do
  echo " metallb: On attend que metallb demarre : $nb_metallb_running / $nb_metallb ... waiting 2s ..."
  sleep 2
  nb_metallb=`kubectl get pods -n metallb-system | grep / | wc -l` 
  nb_metallb_running=`kubectl get pods -n metallb-system | grep Running | grep / | wc -l` 
done
echo " metallb: $nb_metallb_running / $nb_metallb"



# IP Pool configuration
echo "metallb : IP pool configuration ..."
cat <<EOF > /tmp/IPAddressPool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  namespace: metallb-system
  name: pool1
spec:
  addresses:
  - $LB_IPrange
EOF
 
 # apply IP Pool configuration
kubectl apply -f /tmp/IPAddressPool.yaml



# On attend que IPpool soit present  (ne fonctionne qu'avec un seul ip pool)
IPpoolCheck=`kubectl get IPAddressPool -n metallb-system | wc -l`
echo " metallb: IPAddressPool = $IPpoolCheck"
while [ "$IPpoolCheck" != "2" ]
do
  echo " metallb: IPAddressPool pas pret ... waiting 2s ..."
  sleep 2
  IPpoolCheck=`kubectl get IPAddressPool -n metallb-system | wc -l`
  echo " metallb: IPpoolCheck = $IPpoolCheck"
  kubectl apply -f ./IPAddressPool.yaml   #  car meme si les pods sont up, qq fois le service met 10s a monter et la commande precedente ne passe pas.
done
echo " metallb: IPAddressPool OK"



# L2 Advertisement config
echo "metallb : L2 Advertisement configuration ..."
cat <<EOF > /tmp/L2Advertisement.yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool1
EOF

 # apply L2 Advertisement configuration
kubectl apply -f /tmp/L2Advertisement.yaml



# On attend que L2Advertisement soit present (ne fonctionne qu'avec un seul advertisement)
L2AdvertisementCheck=`kubectl get L2Advertisement -n metallb-system | wc -l`
echo " metallb: L2Advertisement = $L2AdvertisementCheck"
while [ "$L2AdvertisementCheck" != "2" ]
do
  echo " metallb: L2Advertisement pas pret ... waiting 2s ..."
  sleep 2
  L2AdvertisementCheck=`kubectl get L2Advertisement -n metallb-system | wc -l`
  echo " metallb: L2Advertisement = $L2AdvertisementCheck"
done
echo " metallb: L2Advertisement OK"

rm -f /tmp/IPAddressPool.yaml
rm -f /tmp/L2Advertisement.yaml



# Kubernetes Dashboard   
# ---------------------
# Le Kubernetes Dashboard depend de metrics-server, il faut l'installer
# -L car redirection
echo "Install du Dashboard Kubernetes ..."
curl -LO  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# comme on est dans un env de test, les certificates sont pas configurés, si on rajoute pas --kubelet-insecure-tls, le pod metrics-server ne demarre pas
sed -i '/kubelet-use-node-status-port/a \        - --kubelet-insecure-tls\' components.yaml
kubectl apply -f components.yaml
rm -f components.yaml

# deploy K8S Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# creation du service de type LoadBalancer
kubectl expose deployment kubernetes-dashboard --type=LoadBalancer --name=service-dashboard -n kubernetes-dashboard
# Il faut que les pods metalLB soit up  =>  au moins un worker node
# Peut prendre quelques minutes pour etre indiqué avec 'get service' =>  si le service est <pending> refaire apres un petit moment
# Si le service reste en pending faire "kubectl apply -f /tmp/IPAddressPool.yaml" pour reappliquer la config IP POOL de Metal LB

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

# create token pour le compte 'default' du namespace 'default', qui a tout les droits:
# et on la mappe sur la variable dashboard_token
dashboard_token=`kubectl create token default -n default`

# Affichage de l'URL du Dashboard et du token
dashboard_svc_ip=`kubectl get services -n kubernetes-dashboard | grep service-dashboard | awk '{print $4}'`
dashboard_svc_port=`kubectl get services -n kubernetes-dashboard| grep service-dashboard | awk '{print $5}' | awk -F: '{print $1}'`
#dashboard_token=`kubectl get secret $(kubectl get serviceaccount default -n default -o jsonpath="{.secrets[0].name}") -n default -o jsonpath="{.data.token}" | base64 --decode`
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
cp /tmp/K8S_Dashboard_Access.info  /root/K8S_Dashboard_Access.info



# Service Monitoring
# ------------------
# Installation d'un service monitoring pipeline à base de cadvisor daemonset
# Configuré pour vRops monitoring: hostPort: 31194
# L'image de cadvisor n'est plus sur dockerhub, mais desormais sur la registry google ici:  https://console.cloud.google.com/gcr/images/google-containers/GLOBAL/
# https://www.kubecost.com/kubernetes-devops-tools/cadvisor/
# --------------------------------------------------------------------------

# clone des yaml de cadvisor
git clone https://github.com/google/cadvisor.git

cd cadvisor/deploy/kubernetes/base

# on remplace le daemonset de cadvisor par celui pour vRops,
curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/Rocky/v1.28/cadvisor_for_vRops_daemonset.yaml
# configuration  de la version de cadvisor
sed -i -e 's/{{cadvisor_version}}/'"$cadvisor_version"'/g'  cadvisor_for_vRops_daemonset.yaml

# kustomize
# necessaire pour mettre les bon tags et namespaces
# conserver 'daemonset.yaml' car sinon il ne le trouve pas et il fait un message d'erreur
kubectl kustomize .

# deploiement
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f cadvisor_for_vRops_daemonset.yaml

cd /tmp
rm -rf cadvisor



# Log Insight agent
# -----------------
# Installation de Log Insight sur le master (pour le monitoring des logs d'audit de K8S)
# Installation de l'agent Log Insight
cd /tmp
git clone https://github.com/ahugla/LogInsight.git  /tmp/li
rpmLI=`ls /tmp/li/$versionLI/*.rpm`
echo "commande d'install Log Insight: " $rpmLI
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



# Copie du contenu d exemple
# ---------------------------
cd /root
git clone https://github.com/ahugla/K8S_yaml.git
cd /tmp


# LOGGING DANS /tmp/K8S_INSTALL.LOG
# ----------------------------------
echo "Phase K8S-MasterConfig terminé"  >> /tmp/K8S_INSTALL.LOG




# COMMANDS
# --------
#   Check certificates :   kubeadm certs check-expiration
#
#   Pull des images containers :  kubeadm config images pull
#   Voir les images containers prevues :  kubeadm config images list
#
#   kubeadm init phase certs all   utile ?

#   voir si le K8S via clusterIP interne repond :  wget https://10.96.0.1:443/api
#   test de connexion au clusterIP de K8S: wget https://10.96.0.1:443/api  (metallb contoller doit pouvoir acceder à 10.96.0.1:443/api)



# necessite de redeployer le dashbaord ???
#   -  delete
#   -  apply 
#   -  service dashboard delete
#   -  service dashboard recreate


# pq nc ne fonctionne pas en K8S ?




