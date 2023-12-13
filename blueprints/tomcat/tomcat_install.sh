#!/bin/bash

#
#  Installe Tomcat 10
#
#  USAGE     tomcat_install  [admin password]
#
#  v1.0
#  1 Aout 2023
#


#https://www.centlinux.com/2022/12/install-apache-tomcat-on-rocky-linux-9.html


cd /tmp

# Set Parameters
URL_TOMCAT=https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.84/bin/apache-tomcat-9.0.84.tar.gz
#URL_TOMCAT=https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.11/bin/apache-tomcat-10.1.11.tar.gz
echo "URL_TOMCAT = "$URL_TOMCAT
admin_passwd=$1



# install pre-requis
dnf install -y wget tar gzip
dnf install -y java-11-openjdk
# pour avoir le tzdb.dat
dnf install -y tzdata-java


#Add user and set the above-created directory its home folder and also disable its login rights
useradd -r -d /opt/tomcat/ -s /sbin/nologin -c "Tomcat User" tomcat


# download tomcat 
curl -O $URL_TOMCAT


# extract tomcat
mkdir /opt/tomcat
tar xf apache-tomcat-*.tar.gz -C /opt/tomcat --strip-components=1


# Grant ownership of /opt/tomcat directory to tomcat user.
chown -R tomcat:tomcat /opt/tomcat/



# Need to create one or more admin users to manage your Tomcat server via Application Manager.
ligne1="<role rolename=\"admin-gui\"/>"
sed -i '/<\/tomcat-users>/i  '"$ligne1"'' /opt/tomcat/conf/tomcat-users.xml
ligne2="<role rolename=\"manager-gui\"/>"
sed -i '/<\/tomcat-users>/i  '"$ligne2"'' /opt/tomcat/conf/tomcat-users.xml
ligne3="<user username=\"admin\" password=\"$admin_passwd\" roles=\"admin-gui,manager-gui\"/>"
sed -i '/<\/tomcat-users>/i  '"$ligne3"'' /opt/tomcat/conf/tomcat-users.xml



# By default Application Manager is allowed to be accessed from localhost only.
# Must edit the following file to make your application manager accessible from other machines within the same network.
sed -i '/Valve className/d' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/Valve className/d' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sed -i '/allow=\"127/d' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i '/allow=\"127/d' /opt/tomcat/webapps/host-manager/META-INF/context.xml



# Create Apache Tomcat service file
# By default, we won’t have a Systemd unit file for Tomcat like the Apache server to stop, start and enable its services.
# Thus, we create one, so that we could easily manage it.
cat <<EOF > /usr/lib/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Server
After=syslog.target network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat

ExecStart=/opt/tomcat/bin/catalina.sh start
ExecStop=/opt/tomcat/bin/catalina.sh stop

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF


# notify systemd
systemctl daemon-reload


# make reboot persistent and start
systemctl enable tomcat
systemctl start tomcat



