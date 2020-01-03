#!/bin/bash

# INSTALL TITO SUR CentOS7.x
#-----------------------------------------------------------------------------
# alex
# 3/01/2020
#
# V1.0
#
#------------------------------------------------------------------------------
# USAGE
#
# Install_Tito_LIagent_WavefrontConfig.sh  [WAVEFRONT_PROXY]  [WAVEFRONT_PORT]
#
#------------------------------------------------------------------------------

# Get and display parameters
WAVEFRONT_PROXY=$1
WAVEFRONT_PORT=$2
echo "WAVEFRONT_PROXY=$WAVEFRONT_PROXY"
echo "WAVEFRONT_PORT=$WAVEFRONT_PORT"

# TITO INSTALL
cd /tmp
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum --enablerepo=remi,remi-php72 install -y httpd php php-common
git clone https://github.com/vmeoc/Tito.git  /var/www/html
cd /var/www/html
git checkout V1.9.6

  
# INSTALL LI AGENT
cd /tmp
git clone https://github.com/ahugla/LogInsight.git  /tmp/li
rpm -ivh "/tmp/li/latest/VMware*.rpm"
sed -i -e 's/;ssl=yes/ssl=no/g'  /var/lib/loginsight-agent/liagent.ini
systemctl restart liagentd
systemctl enable liagentd
rm -rf /tmp/li
  

# WAVEFRONT CONFIG
cd /tmp
sed -i -e "s/getenv('PROXY_NAME')/"\"$WAVEFRONT_PROXY\""/g"   /var/www/html/getTrafficData.php
sed -i -e "s/getenv('PROXY_PORT')/$WAVEFRONT_PORT/g"   /var/www/html/getTrafficData.php


# Start Web Server
systemctl start httpd
systemctl enable httpd


