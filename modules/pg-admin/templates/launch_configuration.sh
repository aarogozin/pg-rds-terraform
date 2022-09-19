#!/bin/bash
echo ECS_CLUSTER=${ECS_CLUSTER} >> /etc/ecs/ecs.config

echo 
mkdir -p /mnt/configs

cat << EOT > /mnt/configs/server.json
${SERVER_CONFIG}
EOT
