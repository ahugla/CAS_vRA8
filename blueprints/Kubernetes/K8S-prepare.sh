#!/bin/bash
#SOURCE : https://mapr.com/blog/making-data-actionable-at-scale-part-2-of-3/

# ALEX H.
# 30 Juin 2020
# v1.10

# USAGE
# -----
#
# cd /tmp
# curl -O https://raw.githubusercontent.com/ahugla/CAS_vRA8/master/blueprints/Kubernetes/K8S-prepare.sh
# chmod 755 $fichierSRC
# ./$fichierSRC
# rm -f $fichierSRC


# Test nombre vCPU
echo "Test nombre vCPU"
nbre_vCPU=`cat /proc/cpuinfo | grep processor | wc -l`
if [ $nbre_vCPU -ge 2 ]
then
  echo "Nombre de cpu superieur ou egal a 2 => OK"
else
  echo "ERROR : PAS ASSEZ DE vCPU (2 minimum)"
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
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


# Install docker : based on "https://kubernetes.io/docs/setup/cri/"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

#Update all (before docker install to avoid last docker version compatibility issue with K8S)
yum update -y 

# to see all available version for a package : yum --showduplicates list docker-ce
yum install -y docker-ce-18.09.9-3.el7   # derniere version supportée à cette date
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


# Install kubernetes repo comme indiqué: "https://kubernetes.io/docs/setup/independent/install-kubeadm/"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF


# Install Kubernetes and start it
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

kubeadm init # Verifie des pre-requis (comme le nombre de cpu) et cree le fichier de config de kubelet: /var/lib/kubelet/config.yaml

systemctl start kubelet
systemctl enable kubelet


