#!/bin/bash
# Usage: ./run_image_tb.sh
# e.g.:  ./run_image_tb.sh
set -e

TB=${1:-haar_compressor_image_tb}
STOP_TIME=${2:-100000ns}
WORKDIR=build

mkdir -p $WORKDIR
mkdir -p sim/output

SRC_FILES=(
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

ghdl -a --workdir=$WORKDIR sim/${TB}.vhd
ghdl -e --workdir=$WORKDIR ${TB}
ghdl -r --workdir=$WORKDIR ${TB} --stop-time=$STOP_TIME