#!/bin/bash
set -x

docker build -t rains .
docker run --name rains-resolver -p 127.0.0.1:5025:5025/tcp -d rains sleep infinity

sleep 2
Address=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rains-resolver)

docker exec -it rains-resolver scripts/Server_all.sh tcp ${Address}