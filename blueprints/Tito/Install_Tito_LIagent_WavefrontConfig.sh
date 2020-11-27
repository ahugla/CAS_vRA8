#!/bin/bash

# INSTALL TITO SUR CentOS7.x
#----------------------------------------------------------------------------------
# alex
# 27/11/2020
#
# V1.1
#
#----------------------------------------------------------------------------------
# USAGE
#
# Install_Tito_LIagent_WavefrontConfig.sh  [WAVEFRONT PROXY FQDN]  [WAVEFRONT PORT]
#
#----------------------------------------------------------------------------------

# Get and display parameters
PROXY_NAME=$1
PROXY_PORT=$2
echo "PROXY_NAME=$PROXY_NAME"
echo "PROXY_PORT=$PROXY_PORT"

# TITO INSTALL
cd /tmp
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum --enablerepo=remi,remi-php72 install -y httpd php php-common
git clone https://github.com/vmeoc/Tito.git  /var/www/html
cd /var/www/html
git checkout V1.9.6

  
# INSTALL ET CONFIG DU LI AGENT
cd /tmp
git clone https://github.com/ahugla/LogInsight.git  /tmp/li
rpm -ivh "/tmp/li/latest/VMware*.rpm"
sed -i -e 's/;ssl=yes/ssl=no/g'  /var/lib/loginsight-agent/liagent.ini
sed -i -e 's/;port=9543/port=9000/g'  /var/lib/loginsight-agent/liagent.ini
systemctl restart liagentd
systemctl enable liagentd
rm -rf /tmp/li
  

# WAVEFRONT CONFIG - set variable for apache in "/etc/sysconfig/httpd"
echo "PROXY_NAME=$PROXY_NAME" >> /etc/sysconfig/httpd
echo "PROXY_PORT=$PROXY_PORT" >> /etc/sysconfig/httpd


# Start Web Server
systemctl start httpd
systemctl enable httpd





