#!/bin/bash
#
# Prepare the uboot binary for Cubieboard4 (CC-A80 board)
#
# you need at least
# apt-get install dos2unix
# And ARM GNU toolchain arm-linux-gnueabihf-xxx
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
curr_dir=`pwd`

#
# Arguments process
#
function show_syntax () {
  echo 
  echo "This script will prepare uboot files for CB4"
  echo 
  echo "The syntax:"
  echo "$1  uboot_bin_dir output_dir"
  echo
}

function exit_process () {
  exit $1
}

if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit_process 1
fi

if [ $# -lt 2 ]; then
    show_syntax $0
    exit_process 1
fi

uboot_bin_dir=$1
output_dir=$2

if [ ! -d $uboot_bin_dir ]; then
    echo "Can't found $uboot_bin_dir"
    exit_process 1
fi

if [ "x$output_dir" != "x" ]; then
    mkdir -p $output_dir
    rm -rf ${output_dir}/*
else
    echo "Can't generate output directory!"
    exit_process 1
fi

#
# Copy Uboot binary
#
#if [ ! -f ${uboot_bin_dir}/boot0_sdcard_sun9iw1p1.bin ]; then
#    echo "Error !! Can't find ${uboot_bin_dir}/boot0_sdcard_sun9iw1p1.bin file"
#    exit_process 1
#fi
#cp ${uboot_bin_dir}/boot0_sdcard_sun9iw1p1.bin ${output_dir}/boot0.bin
#
#if [ ! -f ${uboot_bin_dir}/u-boot-sun9iw1p1.bin ]; then
#    echo "Error !! Can't find ${uboot_bin_dir}/u-boot-sun9iw1p1.bin file"
#    exit_process 1
#fi
#cp ${uboot_bin_dir}/u-boot-sun9iw1p1.bin ${output_dir}/u-boot.bin


if [ ! -f ${uboot_bin_dir}/extract/boot0.bin ]; then
    echo "Error !! Can't find ${uboot_bin_dir}/extract/boot0.bin file"
    exit_process 1
fi
cp ${uboot_bin_dir}/extract/boot0.bin ${output_dir}/boot0.bin

if [ ! -f ${uboot_bin_dir}/extract/u-boot.bin ]; then
    echo "Error !! Can't find ${uboot_bin_dir}/extract/u-boot.bin file"
    exit_process 1
fi
cp ${uboot_bin_dir}/extract/u-boot.bin ${output_dir}/u-boot.bin


#
# Convert fex file to bin
#
#board_mele_file=${uboot_bin_dir}/sys_config.fex
#
#if [ ! -f $board_mele_file ]; then
#    echo "Error !! Can't find $board_mele_file file"
#    exit_process 1
#fi
#cp $board_mele_file ${output_dir}/board_mele.fex
#dos2unix ${output_dir}/board_mele.fex
#
#if [ ! -x ${uboot_bin_dir}/tools/script ]; then
#    echo "Error !! Can't execute  ${uboot_bin_dir}/tools/script"
#    exit_process 1
#fi
#${uboot_bin_dir}/tools/script ${output_dir}/board_mele.fex
#
#if [ ! -f ${output_dir}/board_mele.bin ]; then
#    echo "Error !! Can't generate ${output_dir}/board_mele.bin file "
#    exit_process 1
#fi

#
# Patch boot0.bin
#
#if [ ! -x ${uboot_bin_dir}/tools/update_boot0 ]; then
#    echo "Error !! Can't execute  ${uboot_bin_dir}/tools/update_boot0"
#    exit_process 1
#fi
#${uboot_bin_dir}/tools/update_boot0 ${output_dir}/boot0.bin ${output_dir}/board_mele.bin SDMMC_CARD

#
# Patch u-boot.bin
#
#if [ ! -x ${uboot_bin_dir}/tools/update_uboot ]; then
#    echo "Error !! Can't execute  ${uboot_bin_dir}/tools/update_uboot"
#    exit_process 1
#fi
#${uboot_bin_dir}/tools/update_uboot ${output_dir}/u-boot.bin ${output_dir}/board_mele.bin


echo "Done"

exit_process 0

