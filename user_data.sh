#!/bin/bash
set -e
yum update -y

yum install -y epel-release
yum install -y erlang rabbitmq-server

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management

systemctl stop rabbitmq-server
echo "XAIFUIBJAVHSEZOKOMHD" > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
systemctl start rabbitmq-server

echo "Waiting for RabbitMQ to start..."
sleep 15

export USERNAME="$(aws ssm get-parameter --name /${environment_name}/rabbit/USERNAME --with-decryption --output text --query Parameter.Value --region ${region})"
export PASS="$(aws ssm get-parameter --name /${environment_name}/rabbit/PASSWORD --with-decryption --output text --query Parameter.Value --region ${region})"

# Create admin user
rabbitmqctl add_user "$USERNAME" "$PASS"
rabbitmqctl set_user_tags "$USERNAME" administrator
rabbitmqctl set_permissions -p / "$USERNAME" ".*" ".*" ".*"
systemctl restart rabbitmq-server

echo "RabbitMQ installation completed successfully!"
