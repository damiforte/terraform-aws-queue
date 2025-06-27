#!/bin/bash
set -e

dnf update -y
rpm --import https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
rpm --import https://packagecloud.io/rabbitmq/erlang/gpgkey

tee /etc/yum.repos.d/rabbitmq_erlang.repo <<EOF
[rabbitmq-erlang]
name=rabbitmq-erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/9/\$basearch
repo_gpgcheck=0
gpgcheck=0
enabled=1
EOF

tee /etc/yum.repos.d/rabbitmq-server.repo <<EOF
[rabbitmq-server]
name=RabbitMQ Server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/\$basearch
repo_gpgcheck=0
gpgcheck=0
enabled=1
EOF

dnf clean all
dnf makecache

dnf install -y erlang rabbitmq-server
systemctl enable --now rabbitmq-server

rabbitmq-plugins enable rabbitmq_management
systemctl stop rabbitmq-server

echo "XAIFUIBJAVHSEZOKOMHD" > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie

# Restart RabbitMQ
systemctl start rabbitmq-server
sleep 15

USERNAME="$(aws ssm get-parameter --name /${environment_name}/rabbit/USERNAME --with-decryption --output text --query Parameter.Value --region ${region})"
PASS="$(aws ssm get-parameter --name /${environment_name}/rabbit/PASSWORD --with-decryption --output text --query Parameter.Value --region ${region})"

rabbitmqctl add_user "$USERNAME" "$PASS"
rabbitmqctl set_user_tags "$USERNAME" administrator
rabbitmqctl set_permissions -p / "$USERNAME" ".*" ".*" ".*"

systemctl restart rabbitmq-server

echo "RabbitMQ installation completed successfully!"
