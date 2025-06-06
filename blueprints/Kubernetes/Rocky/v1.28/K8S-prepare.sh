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
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/Rocky/v1.28/K8S-prepare.sh
# chmod 755 K8S-prepare.sh
# ./K8S-prepare.sh 
# rm -f K8S-prepare.sh


# Install old version of K8S, get binaries:  https://flex-solution.com/page/blog/install-k8s-lower-than-1_24




# clean out all your DNF cache (for all repos, even those configured as 'disabled' by default)
#dnf --enablerepo=\* clean all
# rebuild the RPM Database indexes
#rpm -vv --rebuilddb



# LOGGING DANS /tmp/K8S_INSTALL.LOG
# ----------------------------------
echo "Phase K8S-prepare debut"  >> /tmp/K8S_INSTALL.LOG


# get parameter
#dockerVersion=19.03.13-3.el7        #  last=20.10.7-3.el7 
#if [ -n "$1" ]; then
#  kubeVersion=$1
#else
#  kubeVersion=1.28.13               #  
#fi
#echo "dockerVersion à installer = $dockerVersion" >> /tmp/K8S_INSTALL.LOG
kubeVersion=1.28.13
echo "kubeVersion à installer = $kubeVersion"     >> /tmp/K8S_INSTALL.LOG



# Test nombre vCPU
echo "Test nombre vCPU"
nbre_vCPU=`cat /proc/cpuinfo | grep processor | wc -l`
if [ $nbre_vCPU -ge 2 ]
then
  echo "Nombre de cpu superieur ou egal a 2 => OK" >> /tmp/K8S_INSTALL.LOG
else
  echo "ERROR : PAS ASSEZ DE vCPU (2 minimum)"     >> /tmp/K8S_INSTALL.LOG
  exit
fi


# Log $PATH
echo "Intial PATH = $PATH"

# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin
echo "New PATH = $PATH"


# Disable SELinux
setenforce 0
sed -i '/^SELINUX./ { s/enforcing/disabled/; }' /etc/selinux/config


# Disable memory swapping
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab



# Used to add a loadable module into the Linux kernel
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter     # indispensable pour flannel
                          # https://docs.microfocus.com/doc/AMX/24.2/SetSystemParameters

# These parameters determine whether packets crossing a bridge are sent to iptables for processing
# sysctl params required by setup, params persist across reboots
# net.bridge.bridge-nf-call-ip6tables=1
cat <<EOF | sudo tee /etc/sysctl.d/98-k8s.conf
net.ipv4.ip_forward=1
net.ipv4.ip_nonlocal_bind=1
net.bridge.bridge-nf-call-iptables=1
net.netfilter.nf_conntrack_max=1000000
EOF
# Apply sysctl params without reboot
sysctl --system



# Update all 
# ATTENTION: DANGEREUX DE LE FAIRE CAR PEUT CONDUIRE A UNE VERSION D'OS NON SUPPORTEE PAR VRA/VSPHERE ET PROVOQUER DES PB DE CLOUD-INIT (ROCKY 9)
# dnf update -y 



# kubeproxy mode ( dans notre cas le kube proxy mode utilise iptables)
# --------------
# mask other FW to make impossible to load
# Rocky 8 uses "nftables" as the backend by default, whereas "Centos 7" uses iptables.
systemctl mask firewalld
systemctl mask nftables
#install iptables et iproute-tc
dnf install -y iptables  iptables-services
systemctl enable iptables.service
#systemctl start iptables.service
#systemctl stop iptables.service


# Eviter le warning :   [WARNING FileExisting-tc]: tc not found in system path
# The Traffic Control utility manages queueing disciplines, their classes and attached filters and actions
dnf install -y  iproute-tc




# INSTALL CONTAINERD (via DOCKER) ON ROCKY
# ---------------------------------------
#echo "Install Docker" >> /tmp/K8S_INSTALL.LOG
#dnf check-update
#dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#dnf install -y docker-ce docker-ce-cli containerd.io
#systemctl enable docker
#systemctl enable containerd

# systemctl start docker
# The Kubernetes v1.24 release actually removed the dockershim from Kubernetes.



# INSTALL CONTAINERD ON ROCKY
# ---------------------------
# The Kubernetes v1.24 release actually removed the dockershim from Kubernetes.
# https://www.be-root.com/2022/05/17/installation-dun-cluster-kubernetes-sur-rocky-linux-8/
# https://kubeedge.io/docs/setup/prerequisites/runtime/
echo "Install Containerd" >> /tmp/K8S_INSTALL.LOG

# En version 8 il faut supprimer des packages qui entrent en conflit avant l'install de docker
isRocky8=`more /etc/os-release  | grep VERSION_ID | grep 8. | wc -l` 
if [ $isRocky8 -eq '1' ] 
then
  echo "C'est un rocky v8"  >> /tmp/K8S_INSTALL.LOG
  dnf -y remove buildah
  dnf -y remove containers-common
else
  echo "C'est pas un rocky v8"  >> /tmp/K8S_INSTALL.LOG
fi

dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
#dnf -y update
dnf install  -y containerd.io

# On genere le fichier de configuration de containerd
containerd config default | tee /etc/containerd/config.toml

# update le registry dans le fichier de config de containerd   
#     => ca marche pas, lors du 'kubeadmn init' on a toujours le warning nsur la registry
# sed -i -e 's/pause:3.6/pause:3.9/g'  /etc/containerd/config.toml

# on met SystemdCgroup à 'true'
sed -i -e 's/SystemdCgroup = false/SystemdCgroup = true/g'  /etc/containerd/config.toml

systemctl enable --now containerd




# INSTALL KUBERNETES ON ROCKY
# --------------------------
# Install old version of K8S, get binaries:  https://flex-solution.com/page/blog/install-k8s-lower-than-1_24
echo "Add repo for kubelet, kubeadm et kubectl" >> /tmp/K8S_INSTALL.LOG
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
# to see all available version : dnf --showduplicates list 'kube*' --disableexcludes=kubernetes
# Exemple : dnf install -y kubelet-1.28.13  --disableexcludes=kubernetes
#echo "dnf update before kubelet, kubeadm et kubectl install" >> /tmp/K8S_INSTALL.LOG
#dnf update -y 
echo "Install kubelet, kubeadm et kubectl" >> /tmp/K8S_INSTALL.LOG
dnf install -y kubelet-$kubeVersion kubeadm-$kubeVersion   kubectl-$kubeVersion  --disableexcludes=kubernetes    # --rpmverbosity=debug
#dnf install -y kubelet-$kubeVersion kubeadm-$kubeVersion   kubectl-$kubeVersion  --disableexcludes=kubernetes 
echo "Enable kubelet" >> /tmp/K8S_INSTALL.LOG
systemctl enable --now kubelet

#The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.



# LOGGING DANS /tmp/K8S_INSTALL.LOG
# ----------------------------------
K8S_VERSION_WITHv=`kubelet --version | awk '{print $2}'`
echo "K8S_VERSION = $K8S_VERSION_WITHv"  >> /tmp/K8S_INSTALL.LOG
echo "Phase K8S-prepare terminé"  >> /tmp/K8S_INSTALL.LOG




# Remarque FQDN ou shortname.
# Si on veut que la commande "kubectl get nodes" retourne des shortnames et pas de FQDN, il faut verifier la config et la modifier si necessaire.
# Verification :  "hostnamectl"   ou   "uname -n"
# Remplacer le name : hostnamectl set-hostname [name]    +   reboot








#  TO DO
# --------

# - enlever les commentaires
# - variabiliser la version de Kubernetes




