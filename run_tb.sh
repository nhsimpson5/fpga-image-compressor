#!/bin/bash
# Usage: ./run_tb.sh <module_name> [stop_time]
# e.g.:  ./run_tb.sh haar_rle_encoder
set -e

MODULE=$1
WORKDIR=build
STOP_TIME=${2:-100000ns}

if [ -z "$MODULE" ]; then
    echo "Usage: ./run_tb.sh <module_name> [stop_time]"
    exit 1
fi

mkdir -p $WORKDIR

SRC_FILES=(
    and_gate
    d_flip_flop
    pixel_register
    rle_encoder
    haar_butterfly
    haar_butterfly_wide
    haar_quantizer
    subband_transpose_buffer
    haar_row_transform
    haar_column_transform
    haar_2d_encoder
    haar_compressor
)

for f in "${SRC_FILES[@]}"; do
    ghdl -a --workdir=$WORKDIR src/${f}.vhd
done

ghdl -a --workdir=$WORKDIR sim/${MODULE}_tb.vhd
ghdl -e --workdir=$WORKDIR ${MODULE}_tb
ghdl -r --workdir=$WORKDIR ${MODULE}_tb --stop-time=$STOP_TIME