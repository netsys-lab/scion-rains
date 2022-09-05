# !/bin/bash
set -e

/root/dispatcher --config $1 &
pid1=$!
echo "Waiting 45 seconds for dispatcher to come up before attempting to start SDNS"
sleep 45;
echo "Starting SDNS"
(while sleep 1; do /root/scion-sdns -config=$2; done) &
pid2=$!

# terminate script if either command terminates
wait -n $pid1 $pid2
# send kill signal to both pids since we don't know which one terminated
kill $pid1 $pid2

