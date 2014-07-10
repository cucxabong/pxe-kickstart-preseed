pxe-kickstart-preseed
==============
**1. Cài đặt PXE Server**

OS |  Ubuntu 12.04 amd64
--- | -----
eth0 | 10.20.0.99/24
eth1 | Internet Access

**Vai trò:**
- DHCP Server
- Internet Gateway
- Local Repository
- TFTP Server

**1.1 Cấu hình Internet Gateway**
```
sed -i -r -e "s/^(#)?\ ?net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/" /etc/sysctl.conf 
sysctl -p
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
```

**2. Cài đặt DHCP Server**
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

**3. Cài đặt TFTP Server**
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

4. Cài đặt Web Server
5. Tạo PXE Boot Menu


