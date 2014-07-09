install
url --url=http://mirrors.digipower.vn/centos/6.5/os/x86_64/
text
skipx
lang en_US.UTF-8
keyboard us
network --onboot yes --device eth0 --bootproto dhcp --nameserver 8.8.8.8,8.8.4.4 --hostname controller --noipv6
rootpw  --iscrypted $1$bxkiTg.P$Wt0KtelvBfMNagXImZUAe.
authconfig --enableshadow --passalgo=sha512
# printf "r00tme" | mkpasswd -s -m md5

selinux --disabled
firewall --disabled

services --disabled auditd,cups,nfslock,postfix
timezone --utc Asia/Ho_Chi_Minh
bootloader --location=mbr --driveorder=sda --append="crashkernel=auto rhgb quiet"
zerombr
ignoredisk --only-use=sda
clearpart --drives=sda --all --initlabel
part /boot --fstype=ext4 --size=200
part swap --size=2048
part / --fstype=ext4 --size=2048
part /home --fstype=ext4 --grow --size=1024

repo --name="CentOS"  --baseurl=http://mirrors.digipower.vn/centos/6.5/os/x86_64

poweroff

%packages --nobase --ignoremissing --excludedocs
@core
openssh
vim
%end

%post
rpm -Uvh http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y salt-minion
sed -r -i 's/^# ?master:.*/master: 10.20.0.99/' /etc/salt/minion
yum update -y
%end
