SUNXI_MEM Driver 

After run the debian from your build image.
You must do below modification to enable the SUNXI_MEM driver.

(1) Load SUNXI_MEM  modules by modified /etc/modules
root@bsms:/etc# cat modules 
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.
# Parameters can be specified after the module name.
sunxi_cedar_mod


