#!/bin/bash
set -x

read -r -a pids <<< $(cat pids.txt)
for pid in "${pids[@]}"
do
    cpulimit -p "$pid" -l 10 -b
done

#ps aux | grep rains
#cpulimit -p 3220 -l 10 -b


