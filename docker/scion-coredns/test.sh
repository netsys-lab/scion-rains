# !/bin/bash
set -e
# TODO: Fail if dispatcher or daemon crash
sleep 10 &
pid1=$!
(while sleep 3; do echo $1; done) &
pid2=$!

echo "waiting"
wait -n $pid1 $pid2
echo "returned"

kill $pid1 $pid2

