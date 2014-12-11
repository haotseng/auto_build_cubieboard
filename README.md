auto_build_cubieboard
=====================

Automatic build uboot, linux-kernel from source code for Cubieboard.

## Prepare
 
Before you start, Some packets must be installed in you environment.

    # apt-get install uboot-mkimage kpartx dosfstools dos2unix
    
And you also need ARM cross-compiler such as "arm-linux-gnueabihf-xxx"

## How to use

    # sudo ./auto_build.sh cb1|cb2|cb3

