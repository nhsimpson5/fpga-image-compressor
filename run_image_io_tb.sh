set -e   # stop immediately if any step fails, instead of running the rest against a broken build
 
WORKDIR=build
STOP_TIME=${2:-100000ns}
mkdir -p $WORKDIR
 
ghdl -a --workdir=$WORKDIR sim/image_io_tb.vhd
ghdl -e --workdir=$WORKDIR image_io_tb
ghdl -r --workdir=$WORKDIR image_io_tb --stop-time=$STOP_TIME
 