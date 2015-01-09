#!/bin/bash
#
# Auto Build the linux kernel & uboot for Cubieboard1 & Cubieboard2 & Cubiebaord3(Cubietruck)
#
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
curr_dir=`pwd`

#
# Functions
#
function show_syntax () {
  echo 
  echo "This script will auto download all source code and build linux kernel and uboot from source code"
  echo "It can build for Cubieboard1, Cubieboard2, Cubieboard3(CubieTruck) or Cubieboard4(CC-A80)"
  echo 
  echo "The syntax:"
  echo "$1  cb1|cb2|cb3|cb4 [kernel_config_file]"
  echo
}

function exit_process () {
  exit $1
}


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

if [ $# -lt 1 ]; then
    show_syntax $0
    exit_process 1
fi

board_type=$1
kernel_config_file=$2

case $board_type in
    cb1 | cb2 | cb3 | cb3-dev | cb4)
        ;;
    *)
        echo "Unknown Board Type"
        exit_process 1
        ;;
esac

#
#  Default directories
#
src_dir=${curr_dir}/src
kernel_src=${src_dir}/kernel_${board_type}
uboot_src=${src_dir}/uboot
sunxi_board_conf_src=${src_dir}/sunxi_board
sunxi_tool_src=${src_dir}/sunxi_tools
cb_config_files_src=${src_dir}/cubie_configs

output_dir=${curr_dir}/output_${board_type}
kernel_output=${output_dir}/kernel
uboot_output=${output_dir}/uboot

#
#  Default variables
#
extra_fw_tgz_file="${curr_dir}/extra_fw.tgz"
kernel_src_download_type=fast
uboot_src_download_type=fast
other_src_download_type=fast

#
# Change some defintions depend on $board_type
#
case $board_type in
    cb1 )
        #extra_fw_tgz_file="no_extra_fw"
        ;;
    cb2 )
        #extra_fw_tgz_file="no_extra_fw"
        ;;
    cb3 )
        ;;
    cb3-dev )
        kernel_src=${curr_dir}/dev/src/kernel_${board_type}
        kernel_src_download_type=full
        ;;
    cb4 )
        ;;
    *)
        echo "Unknown Board Type"
        exit_process 1
        ;;
esac


#
# Create directorys
#
mkdir -p $src_dir
mkdir -p $output_dir

#
# Download linux kernel source code from internet
#
if [ ! -d $kernel_src ]; then
    echo "[Downloading Linux Source code..]"
    ./download_linux_kernel_src.sh $board_type $kernel_src_download_type $kernel_src
    if [ $? -ne 0 ]; then
        echo "!!! Download linux kernel srouce code error !!!"
        exit_process 1
    fi
fi

#
# Download uboot source code form internet
# The Cubieboard4(CC-A80) doesn't have source code, yet.
# We only have binary file for it.
#
if [ "x$board_type" != "xcb4" ]; then
    if [ ! -d $uboot_src ]; then
        echo "[Downloading UBOOT Source code..]"
        ./download_uboot_src.sh $uboot_src_download_type $uboot_src
        if [ $? -ne 0 ]; then
            echo "!!! Download uboot srouce code error !!!"
            exit_process 1
        fi
    fi
fi

#
# Download board config file for uboot from internet
#
if [ ! -d $sunxi_board_conf_src ]; then
    echo "[Downloading SUNXI Board Config Source code..]"
    ./download_sunxi_board_src.sh $other_src_download_type $sunxi_board_conf_src
    if [ $? -ne 0 ]; then
        echo "!!! Download sunxi bord config srouce code error !!!"
        exit_process 1
    fi
fi

if [ ! -d $sunxi_tool_src ]; then
    echo "[Downloading SUNXI Tools Source code..]"
    ./download_sunxi_tool_src.sh $other_src_download_type $sunxi_tool_src
    if [ $? -ne 0 ]; then
        echo "!!! Download sunxi tool srouce code error !!!"
        exit_process 1
    fi
fi

if [ ! -d $cb_config_files_src ]; then
    echo "[Downloading CubieBoard Config Files Source code..]"
    ./download_cubieboard_configs_src.sh $other_src_download_type $cb_config_files_src
    if [ $? -ne 0 ]; then
        echo "!!! Download cubieboard config files  srouce code error !!!"
        exit_process 1
    fi
fi

#
# Build Linux kernel
#
echo "[Building linux kernel..]"
./build_kernel.sh $board_type $kernel_src $kernel_output $extra_fw_tgz_file $kernel_config_file
if [ $? -ne 0 ]; then
    echo "!!! Build linux kernel error !!!"
    exit_process 1
fi

#
# Build Uboot
#
if [ "x$board_type" == "xcb4" ]; then
    echo "[Copy UBoot binary..]"
    ./cb4_prepare_uboot.sh ./cb4_uboot_bin $uboot_output
else
    echo "[Building UBoot..]"
    ./build_uboot.sh $board_type $uboot_src $sunxi_board_conf_src $sunxi_tool_src $uboot_output
    if [ $? -ne 0 ]; then
        echo "!!! Build UBOOT error !!!"
        exit_process 1
    fi
fi

echo "Done"

exit_process 0

