Wireless on CubieTrunk (CB3)

After run the debian from your build image.
You must do below modification to let the wifi work.

(1) Load wifi modules(gpio_sunxi and ap6210) by modified /etc/modules and /etc/modprobe.d/*.conf (Debian8 only)
Debian 7
===========================
root@bsms:# cat /etc/modules 
gpio_sunxi
ap6210 op_mode=2
sunxi_cedar_mod


Debian 8
===========================
root@bsms:# cat /etc/modules 
gpio_sunxi
ap6210 
sunxi_cedar_mod

root@bsms:# cat /etc/modprobe.d/ap6210.conf
options ap6210 op_mode=2


(2) Modify the /etc/network/interface
Debian 7
===========================
root@bsms:/etc/network# cat interface 
## setup wifi
auto wlan0
iface wlan0 inet dhcp
pre-up ip link set wlan0 up
pre-up iwconfig wlan0 essid your_essid
wpa-ssid your_essid
wpa-psk your_password
wpa-scan_ssid 1

Debian 8
===========================
root@bsms:/etc/network# cat interface 
## setup wifi
auto wlan0
iface wlan0 inet dhcp
wpa-ssid your_essid
wpa-psk your_password

