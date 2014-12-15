auto_build_cubieboard
=====================

Automatic build uboot, linux-kernel from source code for Cubieboards. Include for CB1,CB2,CB3,CB4

## Prepare
 
Before you start, Some packets must be installed in you environment.

    # apt-get install uboot-mkimage kpartx dosfstools dos2unix
    
And you also need ARM cross-compiler such as "arm-linux-gnueabihf-xxx" and "arm-linux-gnueabi-xxx"

## How to use

    # sudo ./auto_build.sh cb1|cb2|cb3|cb4


***

## Note

If you are using CB4(CC-A80)board and update the u-boot to image file or target device.
You must also update the kernel again. Because the CB4's u-boot change the content of linux kernel image file(uImage).
You need to give it a clean kernel image , otherwise it will cause some driver failed.

