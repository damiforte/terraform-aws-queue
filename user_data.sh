#!/bin/bash
set -e

if [[ -z "${environment_name}" || -z "${region}" ]]; then
    echo "Error: environment_name and region variables must be set"
    exit 1
fi

sudo dnf update -y
sudo rpm --import https://packagecloud.io/rabbitmq/erlang/gpgkey
sudo rpm --import https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey

sudo tee /etc/yum.repos.d/rabbitmq_erlang.repo <<EOF
[rabbitmq-erlang]
name=rabbitmq-erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/9/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
EOF

sudo tee /etc/yum.repos.d/rabbitmq-server.repo <<EOF
[rabbitmq-server]
name=RabbitMQ Server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
EOF

sudo dnf install -y erlang rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

sudo rabbitmq-plugins enable rabbitmq_management

sudo systemctl stop rabbitmq-server

ERLANG_COOKIE="$(aws ssm get-parameter --name /${environment_name}/rabbit/ERLANG_COOKIE --with-decryption --output text --query Parameter.Value --region ${region} 2>/dev/null || echo 'XAIFUIBJAVHSEZOKOMHD')"

echo "${ERLANG_COOKIE}" | sudo tee /var/lib/rabbitmq/.erlang.cookie > /dev/null
sudo chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
sudo chmod 400 /var/lib/rabbitmq/.erlang.cookie

sudo systemctl start rabbitmq-server

echo "Waiting for RabbitMQ to start..."
for i in {1..30}; do
    if sudo rabbitmqctl status >/dev/null 2>&1; then
        echo "RabbitMQ is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Timeout waiting for RabbitMQ to start"
        exit 1
    fi
    sleep 2
done

USERNAME="$(aws ssm get-parameter --name /${environment_name}/rabbit/USERNAME --with-decryption --output text --query Parameter.Value --region ${region})"
PASS="$(aws ssm get-parameter --name /${environment_name}/rabbit/PASSWORD --with-decryption --output text --query Parameter.Value --region ${region})"

sudo rabbitmqctl add_user "$USERNAME" "$PASS"
sudo rabbitmqctl set_user_tags "$USERNAME" administrator
sudo rabbitmqctl set_permissions -p / "$USERNAME" ".*" ".*" ".*"
sudo systemctl restart rabbitmq-server

echo "RabbitMQ installation completed successfully!"
echo "Management interface available at: http://$(hostname -I | awk '{print $1}'):15672"
