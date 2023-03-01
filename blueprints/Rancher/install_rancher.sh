#!/bin/bash


# install Docker on Rocky Linux
# ----------------------------- 
#https://www.golinuxcloud.com/install-rancher-rocky-linux-9/

cd /tmp


# Update PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/root/bin

# Disable SELinux
setenforce 0
sed -i '/^SELINUX./ { s/enforcing/disabled/; }' /etc/selinux/config

# Disable memory swapping
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Enable bridged networking and set iptables
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# on desinstalle les eventuelles versions precedentes
dnf -y remove docker docker-common docker-selinux docker-engine

dnf update -y

dnf -y install device-mapper-persistent-data lvm2

dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin --allowerasing

systemctl enable docker --now
#systemctl status docker
docker --version




# install rancher
# ---------------
modprobe ip_tables
#docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:v2.4.9  # =>  OK
docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher          # =>  NO OK si pas de 'modprobe ip_tables'
# WAIT 60s le temps que le container demarre completement
# acces:   http://ip
sleep 60
rancherContainerID=`docker ps | grep rancher | awk '{print $1}'`
defaultBootstrapPassword=`docker logs $rancherContainerID 2>&1 | grep "Bootstrap Password:"`

echo "------------------------ RANCHER DEFAULT PASSWORD ----------------------"  > /tmp/RancherDefaultPassword.txt
echo "-" >> /tmp/RancherDefaultPassword.txt
echo "-" >> /tmp/RancherDefaultPassword.txt
echo $defaultBootstrapPassword  >> /tmp/RancherDefaultPassword.txt
echo "-" >> /tmp/RancherDefaultPassword.txt
echo "-" >> /tmp/RancherDefaultPassword.txt
echo "------------------------------------------------------------------------" >> /tmp/RancherDefaultPassword.txt
cp /tmp/RancherDefaultPassword.txt /root/RancherDefaultPassword.txt
