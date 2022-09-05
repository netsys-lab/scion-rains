# !/bin/bash
set -e
/root/dispatcher --config $1 &
pid1=$!
/root/control --config $2 &
pid2=$!

# terminate script if either command terminates
wait -n $pid1 $pid2
# send kill signal to both pids since we don't know which one terminated
kill $pid1 $pid2
