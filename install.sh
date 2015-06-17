#!/bin/bash
#Shell Install Oracle
#Create By The Linux Bash Shell

clear
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, use sudo sh $0"
    exit 1
fi

echo "XLinux"
echo "Shell Script Instal Oracle"
echo "Create By Linux Bash Shell"
echo "https://www.facebook.com/bashshell.vn"

#get interface
int=$(route -ne | grep UG | awk '{print $8}')
gwa=$(route -ne | grep UG | awk '{print $2}')
ipaddr=$(ip a  | grep $int | grep inet | awk '{print $2}' | cut -f1 -d'/')
nmask=$(ifconfig eth0 | grep Mask | awk '{print $4}' | cut -f2 -d':')
checkdhcp=$(cat /etc/sysconfig/network-scripts/ifcfg-$int | grep 'BOOTPROTO' | cut -f2 -d'=')
if [ "$checkdhcp" == "dhcp" ] || [ "$checkdhcp" == "DHCP" ]; then
echo "Interface $int using configure DHCP."
				while true; do
					echo "Do you want to Configure static interface $int"
					echo "If you input y, Y, YES to change and n, N or NO to exit."
					read -p "Please talk to me ...: " INPUT_STRING
					case $INPUT_STRING in
						c|C|y|Y|yes|YES"")
cat > /etc/sysconfig/network-scripts/ifcfg-$int << eof
DEVICE=$int
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=none
IPADDR=$ipaddr
NETMASK=$nmask
GATEWAY=$gwa
DNS1=8.8.8.8
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=yes
IPV6INIT=no
NAME="System $int"
eof
echo "Configure static interface $int success full"
							break
						;;
						n|N|no|NO)
						echo "Thanks You. You chose Exit"
						break
						;;
					esac
				done
				/etc/init.d/network restart
fi


setenforce 0 
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
yum -y groupinstall "X Window System" 
yum -y groupinstall "Desktop" 
yum -y groupinstall "General Purpose Desktop"
yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 ksh elfutils-libelf elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make sysstat unixODBC unixODBC-devel 

yum -y install tigervnc-server
yum -y update

clear
sed -i 's/net.bridge.bridge-nf-call-ip6tables = 0/#net.bridge.bridge-nf-call-ip6tables = 0/g' /etc/sysctl.conf
sed -i 's/net.bridge.bridge-nf-call-iptables = 0/#net.bridge.bridge-nf-call-iptables = 0/g' /etc/sysctl.conf
sed -i 's/net.bridge.bridge-nf-call-arptables = 0/#net.bridge.bridge-nf-call-arptables = 0/g' /etc/sysctl.conf

#Configure sysctl

echo  'net.ipv4.ip_local_port_range = 9000 65500' >> /etc/sysctl.conf
echo 'fs.file-max = 6815744' >> /etc/sysctl.conf
sed -i 's/kernel.shmall/#kernel.shmall/g' /etc/sysctl.conf
sed -i 's/kernel.shmmax/#kernel.shmmax/g' /etc/sysctl.conf
echo 'kernel.shmall = 10523004' >> /etc/sysctl.conf
#sed -i 's/kernel.shmall = 4294967296/kernel.shmall = 10523004/g' /etc/sysctl.conf
echo 'kernel.shmmni = 4096' >> /etc/sysctl.conf
echo 'kernel.sem = 250 32000 100 128' >> /etc/sysctl.conf
echo 'net.core.rmem_default=262144' >> /etc/sysctl.conf
echo 'net.core.wmem_default=262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max=4194304' >> /etc/sysctl.conf
echo 'net.core.wmem_max=1048576' >> /etc/sysctl.conf
echo 'fs.aio-max-nr = 1048576' >> /etc/sysctl.conf

#configure /etc/security/limits.conf
echo 'oracle   soft   nproc   2047' >> /etc/security/limits.conf
echo 'oracle   hard   nproc   16384' >> /etc/security/limits.conf
echo 'oracle   soft   nofile   1024' >> /etc/security/limits.conf
echo 'oracle   hard   nofile   65536' >> /etc/security/limits.conf

#Check mem using hugpage
memtotal=$(cat /proc/meminfo  | grep 'MemTotal' | awk '{print $2}')
memtotal=$(expr $memtotal / 1024)
	if ( $memtotal -gt 4096 ); then
		maxmem=$(expr $memtotal \* 0.4)
		shmax=$(expr $maxmem \* 1024 \* 1024)
		mlock=$(expr $maxmem \* 1024)
		hugpage=$(expr $maxmem / 2)
		echo "kernel.shmmax=$shmax" >> /etc/sysctl.conf
		echo "vm.nr_hugepages=$hugpage" >> /etc/sysctl.conf
		echo 'oracle   soft memlock $mlock' >> /etc/security/limits.conf
		echo 'oracle   soft hard $mlock' >> /etc/security/limits.conf
	else
		echo 'kernel.shmmax = 6465333657' >> /etc/sysctl.conf
	fi

/sbin/sysctl -p


echo "đang tiến hành chỉnh sửa 1 số thông tin. Xin chờ một chút...."
#change limit file
cat >/etc/security/limits.d/90-nproc.conf<<eof
# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.

*          -    nproc     16384
root       soft    nproc     unlimited

eof

#change Login file
cat >/etc/pam.d/login<<eof
#%PAM-1.0
auth [user_unknown=ignore success=ok ignore=ignore default=bad] pam_securetty.so
auth       include      system-auth
account    required     pam_nologin.so
account    include      system-auth
password   include      system-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_console.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open
session    required     pam_namespace.so
session    required     pam_limits.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
-session   optional     pam_ck_connector.so
eof


echo 'if [ $USER = "oracle" ]; then' >> /etc/profile
echo '     if [ $SHELL = "/bin/ksh" ]; then' >> /etc/profile
echo '          ulimit -p 16384' >> /etc/profile
echo '          ulimit -n 65536' >> /etc/profile
echo '      else' >> /etc/profile
echo '          ulimit -u 16384 -n 65536' >> /etc/profile
echo '     fi' >> /etc/profile
echo 'fi' >> /etc/profile

#creat random password
passvnc=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c 13)
passvncora=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c 13)
passora=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c 13)

echo "Password Login VNC Root: "$passvnc > /root/.pass_install
echo "Password Login VNC Oracle: "$passvncora >> /root/.pass_install
echo "Password Login Oracle: "$passora >> /root/.pass_install
chmod u=rw,g=,o= /root/.pass_install
chattr +i /root/.pass_install
#change host file
echo "127.0.0.1 " $(hostname) >> /etc/hosts

#configure oracle user
groupadd -g 200 oinstall 
groupadd -g 201 dba 
useradd -u 440 -g oinstall -G dba oracle 

echo $passora | passwd --stdin oracle
echo 'umask 022' >> /home/oracle/.bash_profile
echo 'export ORACLE_BASE=/home/oracle/app' >> /home/oracle/.bash_profile
echo 'export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1' >> /home/oracle/.bash_profile
echo 'export PATH=$PATH:$ORACLE_HOME/bin' >> /home/oracle/.bash_profile

#change pass vnc  root
vncpasswd <<eof
$passvnc
$passvnc
eof



#change configure vncserver
echo 'VNCSERVERS="1:root 2:oracle"' >> /etc/sysconfig/vncservers
echo 'VNCSERVERARGS[1]="-geometry 1024x768"' >> /etc/sysconfig/vncservers
echo 'VNCSERVERARGS[2]="-geometry 1024x768"' >> /etc/sysconfig/vncservers

cat > /etc/oratab <<eof
#



# This file is used by ORACLE utilities.  It is created by root.sh
# and updated by the Database Configuration Assistant when creating
# a database.

# A colon, ':', is used as the field terminator.  A new line terminates
# the entry.  Lines beginning with a pound sign, '#', are comments.
#
# Entries are of the form:
#   $ORACLE_SID:$ORACLE_HOME:<N|Y>:
#
# The first and second fields are the system identifier and home
# directory of the database respectively.  The third filed indicates
# to the dbstart utility that the database should , "Y", or should not,
# "N", be brought up at system boot time.
#
# Multiple entries with the same $ORACLE_SID are not allowed.
#
#
eof
service vncserver start
chkconfig vncserver on
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -X
iptables -Z
iptables -F
service iptables save
mv $(dirname $0)/oracle_file.zip /home/oracle/
cd /home/oracle
unzip oracle_file.zip
chown -R oracle. /home/oracle
chown -R oracle. /etc/oratab
chmod +x -R /home/oracle
rm -rf oracle_file.zip
#
cp $(dirname $0)/bin/coraenv.sh /usr/local/bin/coraenv
chmod +x /usr/local/bin/coraenv
#
cp $(dirname $0)/bin/oraenv.sh /usr/local/bin/oraenv
chmod +x /usr/local/bin/oraenv
#
cp $(dirname $0)/bin/dbhome.sh /usr/local/bin/dbhome
chmod +x /usr/local/bin/dbhome
#change pass vnc oracle
su - oracle -c "vncpasswd"<<eof
$passvncora
$passvncora
eof

echo 'sqlnet.authentication_services=(none)' >> /home/oracle/app/product/11.2.0/dbhome_1/network/admin/sqlnet.ora
chown -R oracle. /home/oracle/app/product/11.2.0/dbhome_1/network/admin/sqlnet.ora
chattr +i /home/oracle/app/product/11.2.0/dbhome_1/network/admin/sqlnet.ora

#create services file
cat > /etc/init.d/oracle << eof
#!/bin/bash
# oracle: Start/Stop Oracle Database 11g R2
#
# chkconfig: 345 90 10
# description: The Oracle Database is an Object-Relational Database Management System.
#
# processname: oracle

. /etc/rc.d/init.d/functions

LOCKFILE=/var/lock/subsys/oracle
ORACLE_HOME=/home/oracle/app/product/11.2.0/dbhome_1
ORACLE_USER=oracle

case "\$1" in
'start')
    if [ -f \$LOCKFILE ]; then
        echo \$0 already running.
        exit 1
    fi
    echo -n \$"Starting Oracle Database:"
    su - \$ORACLE_USER -c "\$ORACLE_HOME/bin/lsnrctl start"
    su - \$ORACLE_USER -c "\$ORACLE_HOME/bin/dbstart \$ORACLE_HOME"
    su - \$ORACLE_USER -c "\$ORACLE_HOME/bin/emctl start dbconsole"
    touch \$LOCKFILE
    ;;
'stop')
    if [ ! -f \$LOCKFILE ]; then
        echo \$0 already stopping.
        exit 1
    fi
    echo -n \$"Stopping Oracle Database:"
    su - \$ORACLE_USER -c "\$ORACLE_HOME/bin/lsnrctl stop"
    su - \$ORACLE_USER -c "\$ORACLE_HOME/bin/dbshut"
    su - \$ORACLE_USER -c "\$ORACLE_HOME/bin/emctl stop dbconsole"
    rm -f \$LOCKFILE
    ;;
'restart')
    \$0 stop
    \$0 start
    ;;
'status')
    if [ -f \$LOCKFILE ]; then
        echo \$0 started.
    else
        echo \$0 stopped.
    fi
    ;;
*)
    echo "Usage: \$0 [start|stop|status]"
    exit 1
esac

exit 0

eof
chmod 755 /etc/rc.d/init.d/oracle

echo "Basic Install Success Full."
echo "IP Address: $ipaddr"
echo 'cat file /root/.pass_install is the view password login'
echo 'VNC port 5901 is login desktop for root'
echo 'VNC port 5902 is login desktop for oracle'
echo "you must reboot the server"
echo "Thanks"

exit $?