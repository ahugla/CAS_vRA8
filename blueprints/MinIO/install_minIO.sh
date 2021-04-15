#   INSTALLATION DE MINIO SUR CENTOS 7.x
#
#  v1.0
#
#  Alexandre Hugla
#  15/04/2021
#
#
#  USAGE :  install_minIO.sh [password]
#



# Recuperation des variables
MinIO_password=$1
echo "MinIO_password = " $MinIO_password


# Set parameters
export MINIO_ACCESS_KEY=minioadmin
export MINIO_VOLUMES="/data"
export MINIO_OPTS="--address :9000"


cd /tmp
yum install -y wget


#download minIO
mkdir /opt/minio
mkdir /opt/minio/bin
wget https://dl.minio.io/server/minio/release/linux-amd64/minio -O /opt/minio/bin/minio
chmod +x /opt/minio/bin/minio



# folder for minio storage file
mkdir /data


# create content bucket et file for test
mkdir /data/testndc
wget https://raw.githubusercontent.com/ahugla/test-bidouille/master/testDoca/stockage_objet_NDC.txt
mv stockage_objet_NDC.txt /data/testndc/



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


