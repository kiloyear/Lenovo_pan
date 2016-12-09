#/bin/bash

portal_root=$1
rpm -ih $portal_root/src/thirdlib/autogen-libopts-5.18-5.el7.x86_64.rpm --force
rpm -ih $portal_root/src/thirdlib/ntp-4.2.6p5-22.el7.centos.2.x86_64.rpm --force
rpm -ih $portal_root/src/thirdlib/ntpdate-4.2.6p5-22.el7.centos.2.x86_64.rpm  --force

cat >&/etc/ntp.conf <<EOF
driftfile /var/lib/ntp/drift
restrict 
restrict 127.0.0.1
restrict ::1
server 127.127.1.0
fudge 127.127.1.0 stratum 8
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF

chkconfig --level 345 ntpd on
service ntpd start
