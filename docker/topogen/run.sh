# !/bin/bash
set -e
sudo chown -R scion /share
./scion.sh topology -d -o /share/output -c /share/topology.json
sed -i 's@/home/scion/scion/@./@g' /share/output/docker-compose.yml
sed -i 's@/share/output/@./@g' /share/output/docker-compose.yml
sed -i 's@image:.*control@image: netsys-lab/scion-control@g' /share/output/docker-compose.yml
sed -i 's@image:.*posix-router@image: netsys-lab/scion-router@g' /share/output/docker-compose.yml
sed -i 's@image:.*daemon@image: netsys-lab/scion-daemon@g' /share/output/docker-compose.yml
