#!/bin/bash
#
# Change the Ethernet MAC address in uboot mele file for Cubieboard1, Cubieboard2 & Cubieboard3
#
# you need at least
# apt-get install uboot-mkimage
# And ARM GNU toolchain arm-linux-gnueabihf-xxx
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
work_dir=`pwd`/_build_tmp
curr_dir=`pwd`

#
# Arguments process
#
function show_syntax () {
  echo 
  echo "This script will change MAC address settings in the mele-file in uboot output directory"
  echo "It can build for Cubieboard1, Cubieboard2 & Cubieboard3"
  echo "The parameter [mac address] is an option. And the format should be 'aabbccddeeffgg'"
  echo "If not set [mac address], it will generate an random mac address for uboot."
  echo 
  echo "The syntax:"
  echo "$1 uboot_output_dir [mac address]"
  echo
}

function exit_process () {
  if [ -d $work_dir ]; then
      rm -rf $work_dir
  fi
  exit $1
}

function generate_dynamic_mac_address () {
  mele_file=$1
  target_addr=$2
  temp_mele_file=${mele_file}.tmp
  if [ "$target_addr" = "" ]; then
    MAC_1="9a"
    MAC_2="9e"
    MAC_3="ae"
    MAC_4=`od -An -N1 -t x1 /dev/random | sed 's/ //g'`
    MAC_5=`od -An -N1 -t x1 /dev/random | sed 's/ //g'`
    MAC_6=`od -An -N1 -t x1 /dev/random | sed 's/ //g'`
    MAC_ADDR=${MAC_1}${MAC_2}${MAC_3}${MAC_4}${MAC_5}${MAC_6}
  else
    MAC_ADDR=$target_addr
  fi
  
  #
  # Remove below lines form $mele_file
  # [dynamic]
  # MAC = "000000000000"
  #
  cat $mele_file | sed 's/\[dynamic\]//g' | sed 's/MAC = \".*\"//g' > $temp_mele_file
  
  #
  # Append new line to $mele_file
  #

  echo "[dynamic]" >> $temp_mele_file
  echo "MAC = \"${MAC_ADDR}\"" >> $temp_mele_file
    
  rm -rf $mele_file
  mv $temp_mele_file $mele_file
}

if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit_process 1
fi

if [ $# -lt 1 ]; then
    show_syntax $0
    exit_process 1
fi

if [ -d $work_dir ]; then
    echo "Working directory $work_dir exist, please remove it before run this script"
    exit 1
fi

output_dir=$1
target_mac_addr=$2

if [ ! -d $output_dir ]; then
    echo "Can't found $output_dir"
    exit_process 1
fi

if [ ! -f ${output_dir}/board_mele.fex ]; then
    echo "Can't found ${output_dir}/board_mele.fex"
    exit_process 1
fi

if [ ! -f ${output_dir}/fex2bin ]; then
    echo "Can't found ${output_dir}/fex2bin"
    exit_process 1
fi

if [ ! -f ${output_dir}/script.bin ]; then
    echo "Can't found ${output_dir}/script.bin"
    exit_process 1
fi

mkdir -p $work_dir
cp ${output_dir}/fex2bin ${work_dir}/fex2bin
cp ${output_dir}/board_mele.fex ${work_dir}/board_mele.fex

#
# Build new script.bin & board_mele.fex for uboot
#
echo "Generate MAC Address"
generate_dynamic_mac_address ${work_dir}/board_mele.fex $target_mac_addr

cd ${work_dir}
./fex2bin board_mele.fex script.bin
cd $curr_dir

if [ ! -f ${work_dir}/script.bin ]; then
    echo "Error !! Can't build ${work_dir}/script.bin file"
    exit_process 1
fi

#
# Copy new board_mele.fex & script.bin to output_dir
#
rm ${output_dir}/script.bin
mv ${work_dir}/script.bin ${output_dir}/script.bin
rm ${output_dir}/board_mele.fex
mv ${work_dir}/board_mele.fex ${output_dir}/board_mele.fex

#
# Finish
#
echo "Done"
exit_process 0

