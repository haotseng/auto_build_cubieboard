#!/bin/bash
#
# Download the SUNXI-LINUX kernel source code from internet
#
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
work_dir=`pwd`/_build_tmp
curr_dir=`pwd`

#
# Arguments process
#
function show_syntax () {
  echo 
  echo "This script will download sunxi linux kernel source code from internet."
  echo 
  echo "The syntax:"
  echo "$1  cb1|cb2|cb3|cb4  fast|full  output_dir "
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

if [ $# -lt 3 ]; then
    show_syntax $0
    exit_process 1
fi

if [ -d $work_dir ]; then
    echo "Working directory $work_dir exist, please remove it before run this script"
    exit 1
fi

board_type=$1
download_type=$2
output_dir=$3

case $board_type in
    cb1 )
        kernel_src_path="https://github.com/linux-sunxi/linux-sunxi"
        ;;
    cb2 )
        #kernel_src_path="https://github.com/cubieboard2/linux-sunxi"
        kernel_src_path="https://github.com/cubieboard/linux-sunxi -b cubie/sunxi-3.4"
        ;;
    cb3 )
        #kernel_src_path="https://github.com/cubieboard2/linux-sunxi -b sunxi-3.4-ct-v101"
        #kernel_src_path="https://github.com/cubieboard2/linux-sunxi -b sunxi-3.4-ct-dev"
        kernel_src_path="https://github.com/cubieboard/linux-sunxi -b cubie/sunxi-3.4"
        ;;
    cb4 )
        kernel_src_path="https://github.com/cubieboard/CC-A80-kernel-source.git"
        ;;
    *)
        echo "Unknown Board Type"
        exit_process 1
        ;;
esac

#
# Choose download file
#
case $download_type in
    fast )
        git_depth="--depth=1"
	;;
    full )
        git_depth=""
	;;
    *)
        echo "Unknown Download Type"
        exit_process 1
        ;;
esac

#
# Download source code
#
git clone $git_depth $kernel_src_path $output_dir


#
# Patch source code
#
kernel_patch_file=${board_type}_kernel_src.patch

if [ -f ${curr_dir}/${kernel_patch_file} ]; then
    cd $output_dir
    patch -p1 < ${curr_dir}/${kernel_patch_file}
    cd ${curr_dir}
fi


