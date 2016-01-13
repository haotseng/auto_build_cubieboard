#!/bin/bash
#
# Download the SUNXI uboot source code from internet
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
  echo "This script will download sunxi uboot source code from internet."
  echo 
  echo "The syntax:"
  echo "$1  fast|full output_dir "
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

if [ $# -lt 2 ]; then
    show_syntax $0
    exit_process 1
fi

if [ -d $work_dir ]; then
    echo "Working directory $work_dir exist, please remove it before run this script"
    exit 1
fi

download_type=$1
output_dir=$2
release_tag=$3

#
# Choose config file
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

uboot_src_path="https://github.com/linux-sunxi/u-boot-sunxi"

git clone $git_depth $uboot_src_path $output_dir
if [ x$release_tag != "x" ]; then
  (cd $output_dir; git checkout $release_tag)
fi 
