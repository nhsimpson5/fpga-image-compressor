#!/bin/bash
# Usage: ./run_tb.sh <module_name>
# e.g.:  ./run_tb.sh and_gate
#        ./run_tb.sh d_flip_flop
set -e

MODULE=$1
WORKDIR=build
STOP_TIME=${2:-1000ns}

if [ -z "$MODULE" ]; then
    echo "Usage: ./run_tb.sh <module_name>"
    exit 1
fi

mkdir -p $WORKDIR

ghdl -a --workdir=$WORKDIR src/${MODULE}.vhd
ghdl -a --workdir=$WORKDIR sim/${MODULE}_tb.vhd
ghdl -e --workdir=$WORKDIR ${MODULE}_tb
ghdl -r --workdir=$WORKDIR ${MODULE}_tb --stop-time=$STOP_TIME