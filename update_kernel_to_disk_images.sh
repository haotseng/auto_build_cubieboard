#!/bin/bash
#
# update the linux kernel into disk_image or device
#
# you need at least
# apt-get install kpartx dosfstools
THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
work_dir=`pwd`/_build_tmp
curr_dir=`pwd`

rootfs="${work_dir}/rootfs"
bootfs="${work_dir}/boot"

#
# Arguments process
#
function show_syntax () {
  echo 
  echo "This script will update linux kernel into the pre-build disk images."
  echo "Before you run this script, please make sure you already install kpartx packages,"
  echo 
  echo "The syntax:"
  echo "$1 img|dev  image_file_name_or_device_name   kernel_output_dir"
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

dev_type=$1
device=$2
kernel_dir=$3

if [ ! -f ${kernel_dir}/uImage ]; then
    echo "Can't found ${kernel_dir}/uImage"
    exit_process 1
fi

if [ ! -f ${kernel_dir}/modules.tar.gz ]; then
    echo "Can't found ${kernel_dir}/modules.tar.gz"
    exit_process 1
fi

mkdir -p $work_dir

case "$dev_type" in
  'img')
      target_image=$device
      if [ ! -f $target_image ]; then
          echo "Error !! The file $target_image isn't exit";
          exit_process 1
      fi
      device=`kpartx -va $target_image | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
      bootp_dmsetup_name=${device}p1
      rootp_dmsetup_name=${device}p2
      device="/dev/mapper/${device}"
      bootp=${device}p1
      rootp=${device}p2
      ;;
  'dev')
      target_image=""
      if ! [ -b $device ]; then
          echo "$device is not a block device"
          exit_process 1
      fi
      if ! [ -b ${device}1 ]; then
          bootp=${device}p1
          rootp=${device}p2
      else
          bootp=${device}1
          rootp=${device}2
      fi
      ;;
  *)
      show_syntax $0
      exit_process 1
      ;;
esac

if ! [ -b $bootp ]; then
    echo "$bootp isn't exist"
    if [ "dev_type" == "img" ]; then
        sleep 3
        kpartx -d $target_image
    fi
    exit_process 1
fi
if ! [ -b $rootp ]; then
    echo "$rootp isn't exist"
    if [ "dev_type" == "img" ]; then
        sleep 3
        kpartx -d $target_image
    fi
    exit_process 1
fi

mkdir -p $rootfs
mkdir -p $bootfs

echo "Begin update the linux kernel.."

mount $rootp $rootfs
mount $bootp $bootfs

rm -rf ${bootfs}/uImage 
cp ${kernel_dir}/uImage $bootfs

cp ${kernel_dir}/modules.tar.gz ${work_dir}/modules.tar.gz
if [ -f ${kernel_dir}/firmware.tar.gz ]; then
    cp ${kernel_dir}/firmware.tar.gz ${work_dir}/firmware.tar.gz
fi
    
rm -rf ${rootfs}/lib/modules
rm -rf ${rootfs}/lib/firmware
cd ${rootfs}/lib
tar -zxvf ${work_dir}/modules.tar.gz
if [ -f ${work_dir}/firmware.tar.gz ]; then
    tar -zxvf ${work_dir}/firmware.tar.gz
fi

sync

cd $curr_dir
sleep 3
umount $bootfs

sleep 3
umount $rootfs

if [ "$dev_type" == "img" ]; then
  #
  # Sometimes the "kpartx -d" can't remove the block device in /dev/mapper.
  # It seems caused by system still using the device mapper.
  # So we use dmsetup command force remove device mapper.
  #
  sleep 3
  dmsetup clear $bootp_dmsetup_name
  dmsetup remove $bootp_dmsetup_name
  sleep 3
  dmsetup clear $rootp_dmsetup_name
  dmsetup remove $rootp_dmsetup_name
  sleep 3
  kpartx -d $target_image
fi

echo "Done"

exit_process 0

