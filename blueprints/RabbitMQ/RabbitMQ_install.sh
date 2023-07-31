
#
#    Install RabbitMQ on Rocky Linux VM
#
#	 31/07/2023
#    v 1.0
#
#    Usage : ./RabbitMQ_install.sh   [admin_password]   [vhost]
#


cd /tmp


# set parameter
admin_password=$1
new_vhost=$2
#echo "admin_password = " $admin_password
echo "new_vhost = " $new_vhost


############
# https://www.atlantic.net/dedicated-server-hosting/how-to-install-and-configure-rabbitmq-server-on-rocky-linux-8/
# install the EPEL repository 
dnf install epel-release curl -y
# install the Erlang and RabbitMQ repository 
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash
# install erlang
dnf install erlang -y
# install rabbitMQ
dnf install rabbitmq-server -y



#make it reboot persistant and start
systemctl enable rabbitmq-server
systemctl start rabbitmq-server



# create user / password
rabbitmqctl add_user admin $admin_password


# assign administrator permissions to the admin user 
rabbitmqctl set_user_tags admin administrator
#rabbitmqctl list_users


# add a new vhost
rabbitmqctl add_vhost /$new_vhost
# rabbitmqctl list_vhosts


# provide admin user permissions on vhosts
rabbitmqctl set_permissions -p /$new_vhost admin ".*" ".*" ".*"


# Enable RabbitMQ Web UI
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server


# Check port is up:     ss -antpl | grep 15672


# Connect using
# http://your-server-ip:15672

