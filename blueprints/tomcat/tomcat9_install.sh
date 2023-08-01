

# Install OpenJDK9
cd /opt
curl -O http://download.java.net/java/GA/jdk9/9.0.1/binaries/openjdk-9.0.1_linux-x64_bin.tar.gz
tar -vxzf openjdk-9.0.1_linux-x64_bin.tar.gz
rm -f openjdk-9.0.1_linux-x64_bin.tar.gz


# Configure PATH
jdkDirName=jdk-9.0.1

export PATH=$PATH:/opt/$jdkDirName/bin
export JAVA_HOME=/opt/$jdkDirName
export JRE_HOME=/opt/$jdkDirName

echo \#UPDATE ALEX >> /root/.bash_profile
echo export PATH=\$PATH:/opt/$jdkDirName/bin >> /root/.bash_profile
echo export JAVA_HOME=/opt/$jdkDirName >> /root/.bash_profile
echo export JRE_HOME=/opt/$jdkDirName >> /root/.bash_profile


# Install Tomcat9
cd /usr/share
curl -O http://mirrors.standaloneinstaller.com/apache/tomcat/tomcat-9/v9.0.2/bin/apache-tomcat-9.0.2.tar.gz
tar -vxzf apache-tomcat-9.0.2.tar.gz
rm -f apache-tomcat-9.0.2.tar.gz
mv apache-tomcat-9.0.2 tomcat9


# Configure CATALINA_HOME
export CATALINA_HOME=/usr/share/tomcat9
echo export CATALINA_HOME=/usr/share/tomcat9 >> /root/.bash_profile

