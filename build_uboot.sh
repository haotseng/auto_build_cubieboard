#!/bin/bash
#
# Build the uboot for Cubieboard1,Cubieboard2 & Cubieboard3
#
# you need at least
# apt-get install uboot-mkimage
# And ARM GNU toolchain arm-linux-gnueabihf-xxx
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
work_dir=`pwd`/_build_tmp
curr_dir=`pwd`

#
# Functions
#
function show_syntax () {
  echo 
  echo "This script will build uboot from source code"
  echo "It can build for Cubieboard1, Cubieboard2 or Cubieboard3"
  echo "Before you run this script, please make sure you already install uboot-mkimage packages,"
  echo "and ARM GNU toolchain arm-linux-gnueabihf-xxx"
  echo 
  echo "The syntax:"
  echo "$1  cb1|cb2|cb3 uboot_src board_cfg_src sunxi_tool_src output_dir"
  echo
}

function exit_process () {
  if [ -d $work_dir ]; then
      rm -rf $work_dir
  fi
  exit $1
}

function added_dynamic_mac_address () {
  mele_file=$1
  MAC_1="9a"
  MAC_2="9e"
  MAC_3="ae"
  MAC_4=`od -An -N1 -t x1 /dev/random | sed 's/ //g'`
  MAC_5=`od -An -N1 -t x1 /dev/random | sed 's/ //g'`
  MAC_6=`od -An -N1 -t x1 /dev/random | sed 's/ //g'`
  MAC_ADDR=${MAC_1}${MAC_2}${MAC_3}${MAC_4}${MAC_5}${MAC_6}
  
  #
  # Remove below lines form $mele_file
  # [dynamic]
  # MAC = "000000000000"
  #
  cat $mele_file | sed 's/\[dynamic\]//g' | sed 's/MAC = \".*\"//g' > ${mele_file}.tmp
  
  #
  # Append new line to $mele_file
  #

  echo "[dynamic]" >> ${mele_file}.tmp
  echo "MAC = \"${MAC_ADDR}\"" >> ${mele_file}.tmp
    
  rm -rf $mele_file
  mv ${mele_file}.tmp $mele_file
}

function added_cb3_wifi_gpio_settings () {
  mele_file=$1
  
  #
  # Remove below lines form $mele_file
  # [gpio_para]
  # gpio_used = 1
  # gpio_num  = 2
  # gpio_pin_1 = port:PH20<1><default><default><1>
  # gpio_pin_2 = port:PH10<0><default><default><0>
  cat $mele_file | sed 's/\[gpio_para\]//g' | sed 's/gpio_used .*//g' | sed 's/gpio_num .*//g' | sed 's/gpio_pin_. .*//g' > ${mele_file}.tmp
  
  #
  # Append new line to $mele_file
  #
  cat << EOF >> ${mele_file}.tmp
[gpio_para]  
gpio_used = 1
gpio_num  = 2
gpio_pin_1 = port:PH20<1><default><default><1>
gpio_pin_2 = port:PH10<0><default><default><0>
EOF
    
  rm -rf $mele_file
  mv ${mele_file}.tmp $mele_file
}

#
# Decide the compiler
#
WORK_MACHINE=`uname -m`

if [ "x$WORK_MACHINE" = "xarmv7l" ]; then
    CROSS_COMPILE_OPTIONS=""
    COMPILER_PREFIX=""
else
    #COMPILER_PREFIX=arm-linux-gnueabihf-
    COMPILER_PREFIX=arm-linux-gnueabi-
    
    CROSS_COMPILE_OPTIONS="CROSS_COMPILE=$COMPILER_PREFIX"
    
fi

which ${COMPILER_PREFIX}gcc
if [ $? -ne 0 ]; then
    echo "!!! Can't found ${COMPILER_PREFIX}gcc in your executable path !!!"
    exit_process 1
fi

#
# Check root right
#
if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit_process 1
fi

#
# Check paramters
#

if [ $# -lt 5 ]; then
    show_syntax $0
    exit_process 1
fi

board_type=$1
uboot_dir=$2
board_cfg_src=$3
sunxi_tool_src=$4
output_dir=$5

#
# Check working directory
#

if [ -d $work_dir ]; then
    echo "Working directory $work_dir exist, please remove it before run this script"
    exit 1
fi

#
# Choose board config file
#
# The setting is used for uboot to select which board you want to you.
# You can get the all board type from the file 'board.cfg' of uboot source code.
case $board_type in
    cb1 )
        # Cubieboard ==> sun4i:CUBIEBOARD,SPL,SUNXI_EMAC,STATUSLED=244
        uboot_board_type=Cubieboard
        board_mele_file=${board_cfg_src}/sys_config/a10/cubieboard.fex
        ;;
    cb2 )
        # Cubieboard2 ==> sun7i:CUBIEBOARD2,SPL,SUNXI_EMAC,STATUSLED=244
        uboot_board_type=Cubieboard2
        board_mele_file=${board_cfg_src}/sys_config/a20/cubieboard2.fex
        ;;
    cb3 )
        # Cubieboard3 ==> sun7i:CUBIEBOARD2,SPL,SUNXI_EMAC,STATUSLED=244
        uboot_board_type=Cubietruck
        board_mele_file=${board_cfg_src}/sys_config/a20/cubietruck.fex
        ;;
    *)
        echo "Unknown Board Type"
        exit_process 1
        ;;
esac

if [ ! -d $uboot_dir ]; then
    echo "Can't found $uboot_dir"
    exit_process 1
fi

if [ ! -d $sunxi_tool_src ]; then
    echo "Can't found $sunxi_tool_src"
    exit_process 1
fi

if [ ! -d $board_cfg_src ]; then
    echo "Can't found $board_cfg_src"
    exit_process 1
fi

mkdir -p $work_dir
if [ "x$output_dir" != "x" ]; then
    mkdir -p $output_dir
    rm -rf ${output_dir}/*
else
    echo "Can't generate output directory!"
    exit_process 1
fi

#
# Build UBoot
#
cd $uboot_dir
echo "Cleanup"
make distclean $CROSS_COMPILE_OPTIONS
echo "Build uboot"
make ${uboot_board_type}_config $CROSS_COMPILE_OPTIONS
make $CROSS_COMPILE_OPTIONS
cd $curr_dir

if [ ! -f ${uboot_dir}/spl/u-boot-spl.bin ]; then
    echo "Error !! Can't build ${uboot_dir}/spl/u-boot-spl.bin file"
    exit_process 1
fi
cp ${uboot_dir}/spl/u-boot-spl.bin $output_dir

if [ ! -f ${uboot_dir}/spl/sunxi-spl.bin ]; then
    echo "Error !! Can't build ${uboot_dir}/spl/sunxi-spl.bin file"
    exit_process 1
fi
cp ${uboot_dir}/spl/sunxi-spl.bin $output_dir

if [ ! -f ${uboot_dir}/u-boot.bin ]; then
    echo "Error !! Can't build ${uboot_dir}/u-boot.bin file"
    exit_process 1
fi
cp ${uboot_dir}/u-boot.bin $output_dir

if [ ! -f ${uboot_dir}/u-boot.img ]; then
    echo "Error !! Can't build ${uboot_dir}/u-boot.img file"
    exit_process 1
fi
cp ${uboot_dir}/u-boot.img $output_dir

#
# Build SUNXI Tools
#
cd $sunxi_tool_src
echo "Cleanup"
make clean
echo "Build fex2bin"
make fex2bin
cd $curr_dir

if [ ! -f ${sunxi_tool_src}/fex2bin ]; then
    echo "Error !! Can't build ${sunxi_tool_src}/fex2bin file"
    exit_process 1
fi
cp ${sunxi_tool_src}/fex2bin ${output_dir}

#
# Build script.bin for uboot
#
echo "Build script.bin"
if [ ! -f $board_mele_file ]; then
    echo "Error !! Can't build $board_mele_file file"
    exit_process 1
fi
cp $board_mele_file ${work_dir}/board_mele.fex

added_dynamic_mac_address ${work_dir}/board_mele.fex

if [ "$board_type" == "cb3" ]; then
    added_cb3_wifi_gpio_settings ${work_dir}/board_mele.fex
fi

cp ${sunxi_tool_src}/fex2bin ${work_dir}
cd ${work_dir}
./fex2bin board_mele.fex script.bin
cd $curr_dir

if [ ! -f ${work_dir}/script.bin ]; then
    echo "Error !! Can't build ${work_dir}/script.bin file"
    exit_process 1
fi
cp ${work_dir}/script.bin $output_dir
cp ${work_dir}/board_mele.fex $output_dir

#
# Generate boot.cmd & boot.scr for uboot
#
echo "Generate boot.cmd & boot.scr"
cd ${work_dir}
cat << EOF > boot.cmd
setenv bootargs console=tty0 console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait panic=10 ${extra}
fatload mmc 0 0x43000000 script.bin
fatload mmc 0 0x48000000 uImage
bootm 0x48000000
EOF

if [ "$board_type" == "cb2" ]; then
    echo "setenv machid 0x00000f35" >> boot.cmd
fi

if [ "$board_type" == "cb3" ]; then
    echo "setenv machid 0x00000f35" >> boot.cmd
fi

mkimage -C none -A arm -T script -d boot.cmd boot.scr
cd $curr_dir

if [ ! -f ${work_dir}/boot.scr ]; then
    echo "Error !! Can't build ${work_dir}/boot.scr file"
    exit_process 1
fi
cp ${work_dir}/boot.cmd $output_dir
cp ${work_dir}/boot.scr $output_dir

echo "Done"

exit_process 0

