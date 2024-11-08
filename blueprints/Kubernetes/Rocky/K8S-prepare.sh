#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 11 Nov 2024
# OS : Rocky Linux
# v2.0


# USAGE
# -----
#
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/K8S-prepare.sh
# chmod 755 K8S-prepare.sh
# ./K8S-prepare.sh  $kubeVersion
# rm -f K8S-prepare.sh


# Install old version of K8S, get bianries:  https://flex-solution.com/page/blog/install-k8s-lower-than-1_24


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


# Enable bridged networking
# Set iptables
# Prerequis à l'init  :  sysctl net.ipv4.ip_forward=1 
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
sysctl --system



#Update all (before docker install to avoid last docker version compatibility issue with K8S)
dnf update -y 




: '
# Install docker : based on "https://kubernetes.io/docs/setup/cri/"
dnf install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

#Update all (before docker install to avoid last docker version compatibility issue with K8S)
dnf update -y 

# to see all available version for a package:  yum list docker-ce --showduplicates | sort -r
#yum install -y docker-ce-18.09.9-3.el7   # derniere version supportée à cette date
#yum install -y docker-ce-19.03.13-3.el7.x86_64   # derniere version supportée à cette date  => a utiliser avec K8S 1.19
dnf install -y docker-ce-$dockerVersion   # derniere version supportée à cette date  => a utiliser avec K8S 1.19

mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
'




# INSTALL DOCKER ON ROCKY
# --------------------------
echo "Install Docker" >> /tmp/K8S_INSTALL.LOG
dnf check-update
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker



# INSTALL KUBERNETES ON ROCKY
# --------------------------
echo "Install kubelet, kubeadm et kubectl" >> /tmp/K8S_INSTALL.LOG
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
dnf install -y kubelet-$kubeVersion   kubeadm-$kubeVersion   kubectl-$kubeVersion  --disableexcludes=kubernetes
systemctl enable --now kubelet






:'
# Install kubernetes repo comme indiqué: "https://kubernetes.io/docs/setup/independent/install-kubeadm/"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF


# Install Kubernetes and start it

#yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
# pour voir toutes les versions dispos: 
#    yum --showduplicates list 'kube*' --disableexcludes=kubernetes
#    yum list --showduplicates kube* --disableexcludes=kubernetes
# kubeVersion=1.17.8   # 1.16.12, 1.17.8, 1.18.5   1.19.1   1.20.7  1.21.1
yum install -y kubelet-$kubeVersion   kubeadm-$kubeVersion   kubectl-$kubeVersion  --disableexcludes=kubernetes

systemctl enable --now kubelet

#The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.
'



# LOGGING DANS /tmp/K8S_INSTALL.LOG
# ----------------------------------
K8S_VERSION_WITHv=`kubelet --version | awk '{print $2}'`
echo "Phase K8S-prepare terminé"  >> /tmp/K8S_INSTALL.LOG
echo "K8S_VERSION = $K8S_VERSION_WITHv"  >> /tmp/K8S_INSTALL.LOG



# Remarque FQDN ou shortname.
# Si on veut que la commande "kubectl get nodes" retourne des shortnames et pas de FQDN, il faut verifier la config et la modifier si necessaire.
# Verification :  "hostnamectl"   ou   "uname -n"
# Remplacer le name : hostnamectl set-hostname [name]    +   reboot








#  TO DO
# --------


# - enlever les commentaires
# - variabiliser la version de docker
# - variabiliser la version de Kubernetes