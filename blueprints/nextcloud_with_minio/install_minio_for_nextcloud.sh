#   INSTALLATION DE MINIO SUR ROCKY9
#
#  v1.0
#
#  Alexandre Hugla
#  03/08/2023
#
#
#  USAGE :  install_minIO.sh [password]
#



# Recuperation des variables
MinIO_password=$1


# Set parameters
export MINIO_ACCESS_KEY=minioadmin
export MINIO_VOLUMES="/data"
export MINIO_OPTS="--address :9000"


cd /tmp
yum install -y wget


# create partition
(echo "n"; echo "p"; echo ""; echo ""; echo ""; echo "w") | fdisk /dev/sdb 
#'lsblk' pour voir

# format partition
mkfs -t ext4 /dev/sdb1
#'lsblk -f'  pour voir

# folder for minio storage file
mkdir /data

# mount 
mount /dev/sdb1 /data
# mount permanent (reboot persistent)
echo "/dev/sdb1               /data         ext4    defaults        0   0"   >> /etc/fstab


#download minIO
mkdir /opt/minio
mkdir /opt/minio/bin
wget https://dl.minio.io/server/minio/release/linux-amd64/minio -O /opt/minio/bin/minio
chmod +x /opt/minio/bin/minio


# create content bucket
mkdir /data/nextcloud


# minIO config
cat >/opt/minio/minio.conf <<EOF
MINIO_VOLUMES=$MINIO_VOLUMES
MINIO_OPTS=$MINIO_OPTS
MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY
MINIO_SECRET_KEY=$MinIO_password
EOF




# create service
cat >/etc/systemd/system/minio.service <<EOF
[Unit]
Description=Minio
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/opt/minio/bin/minio

[Service]
WorkingDirectory=/root
User=root
Group=root

PermissionsStartOnly=true
EnvironmentFile=/opt/minio/minio.conf
ExecStartPre=/bin/bash -c "[ -n \"${MINIO_VOLUMES}\" ] || echo \"Variable MINIO_VOLUMES not set in /opt/minio/minio.conf\""

ExecStart=/opt/minio/bin/minio server ${MINIO_OPTS} ${MINIO_VOLUMES}

StandardOutput=journal
StandardError=inherit

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0

# SIGTERM signal is used to stop Minio
KillSignal=SIGTERM
SendSIGKILL=no
SuccessExitStatus=0

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
systemctl daemon-reload
systemctl start minio
systemctl enable minio


# Install le commande line mc, l'equivalent de kubectl pour minio
curl https://dl.min.io/client/mc/release/linux-amd64/mc  --create-dirs -o $HOME/minio-binaries/mc
chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/


# configurer l'alias 'local' de mc  (equivalent d'un configfile pour K8S) pour donner les droits d'acces
# local est l'alias utilisé (le contexte qui contient les credentials), il existe par defaut et pointe vers le s3 minio local
#mc alias set ALIAS URL ACCESSKEY SECRETKEY
mc alias set local http://localhost:9000 $MINIO_ACCESS_KEY $MinIO_password  
#mc admin info local   #verification

     
#create policy   "./policyminio.json":
cat <<EOF > ./policyminio.json
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Action": [
    "admin:*"
   ]
  },
  {
   "Effect": "Allow",
   "Action": [
    "kms:*"
   ]
  },
  {
   "Effect": "Allow",
   "Action": [
    "s3:*"
   ],
   "Resource": [
    "arn:aws:s3:::*"
   ]
  }
 ]
}
EOF


# creer un token pour minioadmin
#mc admin user svcacct add  --access-key "myuserserviceaccount"   --secret-key "myuserserviceaccountpassword"  --policy "/path/to/policy.json"   alias  user
# local est l'alias utilisé (le contexte qui contient les credentials), il existe par defaut et pointe vers le s3 minio local
echo `mc admin user svcacct add --policy ./policyminio.json local minioadmin` > /root/minioTokenForNextcloud
    #=>   Access Key: 8D2JSDWEQJY93V7JGK96 Secret Key: zVfI4HrSKB2+azu96q3D97cow0QXQE5Wgr88k2d6 Expiration: no-expiry

rm -f ./policyminio.json




