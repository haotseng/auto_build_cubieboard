Wireless on CubieTrunk (CB3)

After run the debian from your build image.
You must do below modification to let the wifi work.

(1) Load wifi modules(gpio_sunxi and bcmdhd) by modified /etc/modules
root@bsms:/etc# cat modules 
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.
# Parameters can be specified after the module name.
gpio_sunxi
bcmdhd

(2) Modify the /etc/network/interface

