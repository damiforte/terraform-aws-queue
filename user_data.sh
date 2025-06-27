#!/bin/bash
yum update -y

yum install -y epel-release
yum install -y erlang

# Install RabbitMQ
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.10.0/rabbitmq-server-3.10.0-1.el8.noarch.rpm
yum localinstall rabbitmq-server-3.10.0-1.el8.noarch.rpm -y

systemctl enable rabbitmq-server
systemctl start rabbitmq-server

rabbitmq-plugins enable rabbitmq_management
systemctl stop rabbitmq-server
echo "XAIFUIBJAVHSEZOKOMHD" > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
systemctl start rabbitmq-server

# Wait for service to be ready
sleep 10

# Create admin user
export USERNAME="$(aws ssm get-parameter --name /${environment_name}/rabbit/USERNAME --with-decryption --output text --query Parameter.Value --region ${region})"
export PASS="$(aws ssm get-parameter --name /${environment_name}/rabbit/PASSWORD --with-decryption --output text --query Parameter.Value --region ${region})"
rabbitmqctl add_user "$USERNAME" "$PASS"
rabbitmqctl set_user_tags "$USERNAME" administrator
rabbitmqctl set_permissions -p / "$USERNAME" ".*" ".*" ".*"
