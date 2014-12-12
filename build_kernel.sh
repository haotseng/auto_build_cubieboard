#!/bin/bash
#
# Build the linux kernel for Cubieboard1 & Cubieboard2 & Cubeiboard3(cubietruck)
#
# you need at least
# apt-get install uboot-mkimage
# ARM GNU cross compile toolchain
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
work_dir=`pwd`/_build_tmp
curr_dir=`pwd`

#ARM_CROSS_COMPILER_PREFIX=arm-linux-gnueabihf-
ARM_CROSS_COMPILER_PREFIX=arm-linux-gnueabi-


#
# Arguments process
#
function show_syntax () {
  echo 
  echo "This script will build linux kernel from source code"
  echo "It can build for Cubieboard1, Cubieboard2 or Cubieboard3(CubieTruck)"
  echo "Before you run this script, please make sure you already install uboot-mkimage packages,"
  echo "and ARM GNU cross compile toolchain"
  echo 
  echo "The syntax:"
  echo "$1  cb1|cb2|cb3|cb4 kernel_src_dir output_dir extra_fw_tgz_file [new_config_file]"
  echo
}

function exit_process () {
  if [ -d $work_dir ]; then
      rm -rf $work_dir
  fi
  exit $1
}

if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit_process 1
fi

if [ $# -lt 4 ]; then
    show_syntax $0
    exit_process 1
fi

if [ -d $work_dir ]; then
    echo "Working directory $work_dir exist, please remove it before run this script"
    exit 1
fi

board_type=$1
kernel_dir=$2
output_dir=$3
extra_fw_file_tgz=$4
update_config_file=$5

if [ ! -d $kernel_dir ]; then
    echo "Can't found $kernel_dir"
    exit_process 1
fi

#
# Choose config file
#
case $board_type in
    cb1 )
        # sun4i_defconfig ==> original default config for A10
        # hao_cb1_defconfig ==> The modified setting for my board
        def_config=hao_cb1_defconfig
        if [ -f ${SCRIPT_PATH}/${def_config} ]; then
            rm -rf ${kernel_dir}/arch/arm/configs/${def_config}
            cp ${SCRIPT_PATH}/${def_config} ${kernel_dir}/arch/arm/configs
        else
            def_config=sun4i_defconfig
        fi
        ;;
    cb2 )
        # sun7i_defconfig ==> original default config for A20
        # hao_cb2_defconfig ==> The modified setting for my board
        def_config=hao_cb2_defconfig
        if [ -f ${SCRIPT_PATH}/${def_config} ]; then
            rm -rf ${kernel_dir}/arch/arm/configs/${def_config}
            cp ${SCRIPT_PATH}/${def_config} ${kernel_dir}/arch/arm/configs
        else
            def_config=sun7i_defconfig
        fi
        ;;
    cb3 )
        # sun7i_defconfig ==> original default config for A20
        # hao_cb3_defconfig ==> The modified setting for my board
        def_config=hao_cb3_defconfig
        if [ -f ${SCRIPT_PATH}/${def_config} ]; then
            rm -rf ${kernel_dir}/arch/arm/configs/${def_config}
            cp ${SCRIPT_PATH}/${def_config} ${kernel_dir}/arch/arm/configs
        else
            def_config=sun7i_defconfig
        fi
        ;;
    cb4 )
        # sun9iw1p1smp_defconfig ==> original default config for A80
        # hao_cb4_defconfig ==> The modified setting for my board
        def_config=hao_cb4_defconfig
        if [ -f ${SCRIPT_PATH}/${def_config} ]; then
            rm -rf ${kernel_dir}/arch/arm/configs/${def_config}
            cp ${SCRIPT_PATH}/${def_config} ${kernel_dir}/arch/arm/configs
        else
            def_config=sun9iw1p1smp_defconfig
        fi
        ;;

    *)
        echo "Unknown Board Type"
        exit_process 1
        ;;
esac
echo "Set kernel config file name : ${def_config}"

if [ "x$output_dir" == "x" ]; then
    echo "Can't generate output directory!"
    exit_process 1
fi
mkdir -p $output_dir

cd $kernel_dir
echo "Make kernel mrproper"
make ARCH=arm CROSS_COMPILE=$ARM_CROSS_COMPILER_PREFIX mrproper 
echo "Make kernel $def_config"
make ARCH=arm CROSS_COMPILE=$ARM_CROSS_COMPILER_PREFIX $def_config
cd $curr_dir
if [ "$update_config_file" != "" ]; then 
    if [ -f $update_config_file ]; then
        echo "Over write .config file with $update_config_file"
        rm -rf ${kernel_dir}/.config
        cp $update_config_file ${kernel_dir}/.config
    fi
fi
cd $kernel_dir
echo "Make kernel uImage modules"
make ARCH=arm CROSS_COMPILE=$ARM_CROSS_COMPILER_PREFIX -j4 uImage modules
echo "Make kernel modules_install"
make ARCH=arm CROSS_COMPILE=$ARM_CROSS_COMPILER_PREFIX INSTALL_MOD_PATH=output modules_install

cd $curr_dir
if [ ! -d ${kernel_dir}/output/lib/modules ]; then
    echo "Compile Error !! The dir ${kernel_dir}/output/lib/modules didn't exist"
    exit_process 1
fi 
cd ${kernel_dir}/output/lib
tar -zcvf modules.tar.gz modules

cd $curr_dir
if [ -f ${extra_fw_file_tgz} ]; then
    mkdir -p ${kernel_dir}/output/lib/firmware
    cd ${kernel_dir}/output/lib/firmware
    tar -zxvf ${extra_fw_file_tgz}
    cd $curr_dir
fi 
if [ -d ${kernel_dir}/output/lib/firmware ]; then
    cd ${kernel_dir}/output/lib
    tar -zcvf firmware.tar.gz firmware 
fi 

cd $curr_dir
rm -rf ${output_dir}/*

mv ${kernel_dir}/output/lib/modules.tar.gz ${output_dir}
if [ -f ${kernel_dir}/output/lib/firmware.tar.gz ]; then
    mv ${kernel_dir}/output/lib/firmware.tar.gz ${output_dir}
fi
cp ${kernel_dir}/arch/arm/boot/uImage ${output_dir}
cp ${kernel_dir}/arch/arm/boot/zImage ${output_dir}
cp ${kernel_dir}/.config ${output_dir}/kernel_config
 
echo "Done"

exit_process 0

