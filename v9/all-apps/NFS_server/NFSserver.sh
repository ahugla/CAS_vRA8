# 
#   DEPLOY NFS SERVER ON ROCKY 9 
#
#   usage:    ./NFSserver.sh   /myshare
#
#----------------------------------------


cd /tmp


# Paramaters
NFSshare=$1
#NFSshare="/nfsshare"
echo "NFSshare = $NFSshare"


# install package
sudo dnf install -y nfs-utils


# Create shared Directory
sudo mkdir -p $NFSshare
sudo chown -R nobody:nobody $NFSshare
sudo chmod 777 $NFSshare


# configure NFS share
# ex : 	/nfsshare *(rw,sync,no_subtree_check,no_root_squash,insecure)
echo "$NFSshare *(rw,sync,no_subtree_check,no_root_squash,insecure)"  > /etc/exports
# rw: This option gives the client computer both read and write access to the volume.
# sync: This option forces NFS to write changes to disk before replying.
# no_subtree_check: This option prevents subtree checking, which is a process where the host must check whether the file is actually still available in the exported tree for every request. This can cause many problems when a file is renamed while the client has it opened. In almost all cases, it is better to disable subtree checking.
# no_root_squash: By default, NFS translates requests from a root user remotely into a non-privileged user on the server. This was intended as security feature to prevent a root account on the client from using the file system of the host as root. no_root_squash disables this behavior for certain shares.


#apply the changes by exporting the shared directories:
sudo exportfs -arv


# openening FW
#sudo firewall-cmd --permanent --zone=public --add-service=nfs
#sudo firewall-cmd --permanent --zone=public --add-service=mountd
#sudo firewall-cmd --permanent --zone=public --add-service=rpc-bind
#sudo firewall-cmd --reload


# Enable et Start service
sudo systemctl enable nfs-server
sudo systemctl start nfs-server 



#
# test 
# ----
# mkdir localDir
# chmod 777 localDir
# mount -t nfs IP:/share   /localDir


