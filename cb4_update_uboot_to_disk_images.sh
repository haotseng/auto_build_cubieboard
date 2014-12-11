#!/bin/bash
#
# update the uboot into disk_image or device
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
  echo "This script will update uboot into the pre-build disk images. It only for CB4 (CC-A80) board"
  echo "Before you run this script, please make sure you already install kpartx packages,"
  echo 
  echo "The syntax:"
  echo "$1 img|dev  image_file_name_or_device_name  uboot_output_dir"
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
uboot_dir=$3

if [ ! -f ${uboot_dir}/u-boot.bin ]; then
    echo "Can't found ${uboot_dir}/u-boot.bin"
    exit_process 1
fi

if [ ! -f ${uboot_dir}/boot0.bin ]; then
    echo "Can't found ${uboot_dir}/boot0.bin"
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

mkdir -p $bootfs

echo "Begin update the uboot files.."

mount $bootp $bootfs

#
# Here, you can copy some files into u-Boot partition
#
# Begin here ==>

# <== End

sync

sleep 3
umount $bootfs

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
  sleep 3
  device=`losetup -f --show $target_image`
fi

dd if=${uboot_dir}/boot0.bin of=$device bs=1024 seek=8
dd if=${uboot_dir}/u-boot.bin of=$device bs=1024 seek=19096

sync

if [ "$dev_type" == "img" ]; then
    sleep 3
    losetup -d $device
fi

echo "Done"
exit_process 0

