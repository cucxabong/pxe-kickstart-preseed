pxe-kickstart-preseed
==============

#0. Nhu cầu
Bài này là 1 note nhỏ về cách cài đặt OS (gồm có CentOS 6.5/7, Ubuntu Server 12.04/14.04) thông qua mạng [sử dụng PXE](http://en.wikipedia.org/wiki/Preboot_Execution_Environment) và [Ubuntu preseed](https://help.ubuntu.com/12.04/installation-guide/i386/preseed-intro.html) và [RedHat Kickstart](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Installation_Guide/ch-kickstart2.html#s1-kickstart2-whatis) để tự động làm 1 số thao tác như chọn Language/Keyboard Layout/Partitioning HDD... để tự động hoàn toàn từ lúc bật Server cho tới khi OS được cài xong, giúp giảm thời gian cài đặt OS và nó cũng 'pro' hơn nữa chứ :).

#1. Cài đặt PXE Server#

OS |  Ubuntu 12.04 amd64
--- | -----
eth0 | 10.20.0.99/24
eth1 | Internet Access

**Vai trò:**
- DHCP Server
- Internet Gateway
- TFTP Server
- Webserver 

**Cấu hình Internet Gateway**
```
sed -i -r -e "s/^(#)?\ ?net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/" /etc/sysctl.conf 
sysctl -p
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
```

#2. Cài đặt DHCP Server
```
apt-get install isc-dhcp-server -y
```
**/etc/dhcp/dhcpd.conf**
```
subnet 10.20.0.0 netmask 255.255.255.0 {
	range 10.20.0.100 10.20.0.200;
	option domain-name-servers 8.8.8.8;
	option routers 10.20.0.99;
	option broadcast-address 10.20.0.255;
	option subnet-mask 255.255.255.0;
	filename "pxelinux.0";
	next-server 10.20.0.99;
}
```
**Restart lại DHCP**
```
service isc-dhcp-server restart
```

#3. Cài đặt TFTP Server
```
apt-get install tftpd-hpa -y
```
**/etc/default/tftpd-hpa**
```
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/pxe/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
```

**Tạo thư mục 'root' cho TFTP**
```
mkdir -p /var/pxe/tftpboot
```
**Restart dịch vụ TFTP**
```
service tftpd-hpa restart
```

**Kiểm tra lại TFTP Server**
```
ps aux | grep tftp
```

**Kết quả giống như dưới là được**
```
10:14   0:00 /usr/sbin/in.tftpd --listen --user tftp --address 0.0.0.0:69 --secure /var/pxe/tftpboot
```
**Chuẩn bị file phục vụ cho quá trình boot từ TFTP**
```
mkdir -p /var/pxe/tftpboot/pxelinux.cfg
cd /var/pxe/tftpboot/
wget http://mirrors.digipower.vn/ubuntu/archive/dists/precise/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/boot-screens/vesamenu.c32
wget http://mirrors.digipower.vn/ubuntu/archive/dists/trusty/main/installer-amd64/current/images/netboot/pxelinux.0
wget https://raw.githubusercontent.com/d0m0reg00dthing/pxe-kickstart-preseed/master/pxelinux.cfg/default -O pxelinux.cfg/default
```

#4. Cài đặt Web Server
```
apt-get install nginx -y
```

**/etc/nginx/sites-enabled/default**
```
server {
	listen       80 default_server;
	server_name  localhost;
	autoindex on;
	root /var/pxe/tftpboot;
	location / {
		    try_files $uri $uri/ =404;
	}
}
```

**Restart nginx**
```
service nginx restart
```

#5. Tạo cấu trúc file/thư mục

###Tạo cấu trúc thư mục
```
mkdir -p /var/pxe/tftpboot/ubuntu/12.04/{amd64,i386}
mkdir -p /var/pxe/tftpboot/ubuntu/14.04/{amd64,i386}
mkdir -p /var/pxe/tftpboot/centos/6.5/{x86_64,i386}
mkdir -p /var/pxe/tftpboot/centos/7/x86_64
mkdir /var/pxe/tftpboot/centos/kickstarts
```

###Tạo kernel và RAM disk
```
cd /var/pxe/tftpboot/centos/6.5/
wget http://mirrors.digipower.vn/centos/6.5/os/i386/images/pxeboot/initrd.img -O i386/initrd.img
wget http://mirrors.digipower.vn/centos/6.5/os/i386/images/pxeboot/vmlinuz -O i386/vmlinuz
wget http://mirrors.digipower.vn/centos/6.5/os/x86_64/images/pxeboot/initrd.img -O x86_64/initrd.img
wget http://mirrors.digipower.vn/centos/6.5/os/x86_64/images/pxeboot/vmlinuz -O x86_64/vmlinuz

# CentOS 7 x86_64
cd /var/pxe/tftpboot/centos/7/x86_64/
wget http://mirrors.digipower.vn/centos/7/os/x86_64/images/pxeboot/initrd.img -O initrd.img
wget http://mirrors.digipower.vn/centos/7/os/x86_64/images/pxeboot/vmlinuz -O vmlinuz

# Ubuntu 12.04 
# 4 file này mình lấy trong file iso 12.04.4 để fix bug https://bugs.launchpad.net/ubuntu/+source/net-retriever/+bug/1067934)
cd /var/pxe/tftpboot/ubuntu/12.04
wget https://github.com/d0m0reg00dthing/pxe-kickstart-preseed/blob/master/ubuntu/12.04/amd64/initrd.gz?raw=true -O amd64/initrd.gz
wget https://github.com/d0m0reg00dthing/pxe-kickstart-preseed/blob/master/ubuntu/12.04/amd64/linux?raw=true -O amd64/linux
wget https://github.com/d0m0reg00dthing/pxe-kickstart-preseed/blob/master/ubuntu/12.04/i386/initrd.gz?raw=true -O i386/initrd.gz
wget https://github.com/d0m0reg00dthing/pxe-kickstart-preseed/blob/master/ubuntu/12.04/i386/linux?raw=true -O i386/linux

# Ubuntu 14.04
cd /var/pxe/tftpboot/ubuntu/14.04/
wget http://mirrors.digipower.vn/ubuntu/archive/dists/trusty/main/installer-i386/current/images/netboot/ubuntu-installer/i386/initrd.gz -O i386/initrd.gz
wget http://mirrors.digipower.vn/ubuntu/archive/dists/trusty/main/installer-i386/current/images/netboot/ubuntu-installer/i386/linux -O i386/linux
wget http://mirrors.digipower.vn/ubuntu/archive/dists/trusty/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/initrd.gz -O amd64/initrd.gz
wget http://mirrors.digipower.vn/ubuntu/archive/dists/trusty/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/linux -O amd64/linux
```

###Tạo kickstart/preceed files
```
# CentOS 6.5 x86_64 kickstart
wget https://raw.githubusercontent.com/d0m0reg00dthing/pxe-kickstart-preseed/master/centos/kickstarts/6.5.x86_64.ks -O /var/pxe/tftpboot/centos/kickstarts/6.5.x86_64.ks

# CentOS 6.5 i386 kickstart
wget https://raw.githubusercontent.com/d0m0reg00dthing/pxe-kickstart-preseed/master/centos/kickstarts/6.5.i386.ks -O /var/pxe/tftpboot/centos/kickstarts/6.5.i386.ks

# CentOS 7 x86_64 kickstart
wget https://raw.githubusercontent.com/d0m0reg00dthing/pxe-kickstart-preseed/master/centos/kickstarts/7.x86_64.ks -O /var/pxe/tftpboot/centos/kickstarts/7.x86_64.ks

# Create ubuntu 12.04 preseed
wget https://raw.githubusercontent.com/d0m0reg00dthing/pxe-kickstart-preseed/master/ubuntu/precise.preseed -O /var/pxe/tftpboot/ubuntu/precise.preseed

# Create ubuntu 14.04 preseed
wget https://raw.githubusercontent.com/d0m0reg00dthing/pxe-kickstart-preseed/master/ubuntu/trusty.preseed -O /var/pxe/tftpboot/ubuntu/trusty.preseed
```

# 6. Booting
Bây giờ bạn chỉ cần cắm server vào chung switch (chung mạng) với PXE Server (10.20.0.99) và chỉnh sửa file /var/pxe/tftpboot/pxelinux.cfg/default để chọn lại 'default boot option' để cài trên hàng loạt server là xong.

Trên chỉ là cấu hình cơ bản, PXE còn có cơ chế tạo ra các boot menu khác nhau dựa vào địa chỉ MAC và địa chỉ IP (Cách này cụ Mirantis đang làm cho Fuel Openstack), cái này thì các bạn phải chịu khó tìm tòi thêm trên Google. Mình xin kết thúc bài ở đây.
