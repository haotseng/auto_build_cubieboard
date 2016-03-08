auto_build_cubieboard
=====================

Automatic build uboot, linux-kernel from source code for Cubieboards. Include for CB1,CB2,CB3,CB4

## Prepare
 
Before you start, Some packets must be installed in you environment.

    # apt-get install uboot-mkimage kpartx dosfstools dos2unix device-tree-compiler
    
And you also need ARM cross-compiler such as "arm-linux-gnueabihf-xxx" and "arm-linux-gnueabi-xxx"

## How to use

    # sudo ./auto_build.sh cb1|cb2|cb3|cb4


***

## Note

(1) If you want to build linux kernel for CB4. It only work with ARM cross-compiler(ARMEL) version 4.6.x 
