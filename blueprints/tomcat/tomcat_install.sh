#!/bin/bash




# Install OpenJDK11
dnf install -y java-11-openjdk.x86_64
#java --version



# Create a non-root user for Tomcat
groupadd tomcat


# Create a directory to save Apache Tomcat files
mkdir /opt/tomcat


#Add user and set the above-created directory its home folder and also disable its login rights
useradd -s /bin/nologin -g tomcat -d /opt/tomcat tomcat


# Download tomcat 10
# voir version dispo:   http://mirrors.standaloneinstaller.com/apache/tomcat/
cd /opt/tomcat
curl -O  http://mirrors.standaloneinstaller.com/apache/tomcat/tomcat-10/v10.1.11/bin/apache-tomcat-10.1.11.tar.gz


# Extract and delete package
tar -zxvf apache-tomcat-*.tar.gz -C /opt/tomcat --strip-components=1
rm -f apache-tomcat-10.1.11.tar.gz


# As we already have created a dedicated user for Tomcat, thus we permit it to read the files available in it
chown -R tomcat: /opt/tomcat


# Allow the script available inside the folder to execute
sh -c 'chmod +x /opt/tomcat/bin/*.sh'


# Create Apache Tomcat service file
# By default, we won’t have a Systemd unit file for Tomcat like the Apache server to stop, start and enable its services.
# Thus, we create one, so that we could easily manage it.
cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat webs servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/jre"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF


# make reboot persistent and start
systemctl enable --now tomcat
systemctl start tomcat
