#!/bin/bash
#
# SCRIPT  : dd_v01.0.sh 
# AUTHOR  : Jyothish N | Linux Administrator <jyothn01@in.ibm.com> 
# DATE    : 13/12/2017
# REV     : 1.0
# PLATFORM: Linux 
# PURPOSE : This script will produce a DD check report in HTML format.
# 
# set -n   # Uncomment to check script syntax, without execution.
#          # NOTE: Do not forget to put the comment back in or
#          #       the shell script will not execute!
# set -x   # Uncomment to debug this shell script

PROGNAME=${0##*/}
VERSION="1.0"

#VARIABLE DECLARATION

OS=`uname`
OS_REL="/etc/redhat-release"
SCRIPT="${0}"
SCRIPTNAME="${SCRIPT%.sh}"
DATE=`date`
HOST=$(uname -n | awk -F. '{print $1}')
HOSTNAME=`hostname`
AUTHOR="Jyothish N"
SOURCE="Linux LCM Team"
CONTACT="jyothn01@in.ibm.com"
FUNCTION="DD Report"
INFO="This script does the DD check on the server and displays the information in HTML format."
TITLE="DD Report for $HOSTNAME"
TIME_STAMP="Generated on $DATE"
# Supported OS
RHEL="Red Hat Enterprise Linux 5 & 6"
VERHIST="
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Version History                                                                         #
# 1.0           Initial release                 13 December, 2017                         #
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"

passed ()
{
        echo -e "[ <font size="3" color="green">PASSED</font> ]"
}
failed ()
{
        echo -e "[ <font size="3" color="red">FAILED</font> ]"
}
warning ()
{
        echo -e "[ <font size="3" color="brown">WARNING</font>]"
}
info ()
{
        echo -e "[ <font size="3" color="blue">INFO</font> ]"
}
tab ()
{
        echo -e "\t\t\t"
}

##########################################################

usage() {
  echo -e "Usage: $PROGNAME [-h|--help] [-v|--version] [-s|--supportedos] [-H|--history] [-i|--info]"
}

###########################################################

printhelp() {
  cat <<- _EOF_
  $PROGNAME ver. $VERSION

  Server DD Report

  $(usage)

  Options:
  -h, --help  Display this [h]elp message and exit.
  -v, --version  Print script [v]ersion.
  -s, --supportedos  [S]upported OS.
  -H, --history  Version [H]istory
  -i, --summary of what the script does.

  NOTE: You must be the superuser to run this script.

_EOF_
  return
}

# Parse command-line
while [[ -n $1 ]]; do
  case $1 in
    -h | --help)
      printhelp; exit 0 ;;
    -v | --version)
      echo "${SCRIPTNAME} | Version: ${VERSION} | Author: ${AUTHOR} | Contact: ${CONTACT}";exit 0;;
    -s | --supportedos)
      echo -e "Supported OS:\n------------\n$OEL\n$RHEL\n$SLES"; echo; exit 0;;
    -H | --history)
      echo "${VERHIST}";exit 0;;
    -i | --info)
      echo "${INFO}";exit 0;;
    -* | --*)
      usage
      echo "Unknown option $1" ; exit 1;;
    *)
      echo "Argument $1 to process..." ;;
  esac
  shift
done

#############################################
# TEST FOR LINUX SERVER AND ROOT USER
#
# check for Linux server
if [ "$OS" != "Linux" ] ; then
        echo "This is not a Linux server. Aborting !!!"
        exit 1
fi

# check for Linux OS
if [ "$OS_REL" != "/etc/redhat-release" ]; then
        echo  "Your OS / OS Release is not supported.";
        exit 1
fi

# check for root UID
if [[ $(id -u) != 0 ]]; then
        echo "You must be root to execute the script. Exiting the script"
        exit 1
fi

###########################################
echo -en "\e[1;34m"
echo -e "\t\t\t\t\t----------------------------------------------------------------"
echo -e "\t\t\t\t\t|                         DD REPORT                        |"
echo -e "\t\t\t\t\t----------------------------------------------------------------"
echo -en "\e[0m"
echo
echo -en "\e[1;34m\t\t\t\t\tThis script will do a DD Check and generate a report in HTML format.\e[0m\n"
echo
echo -en "\e[1;34m\t\t\t\tUsage: $PROGNAME [-h|--help] [-v|--version] [-s|--supportedos] [-H|--history] [-i|--info]\e[0m\n"
############################################

############################################
# System
SL_NO=$(dmidecode -t system | grep -i "Serial Number" | awk -F : {'print $2'} | xargs )
SYS_MAN=$(dmidecode -t system | grep -i "Manufacturer" | awk -F : {'print $2'} | xargs)
SYS_MODEL=$(dmidecode -t system | grep -i "Product Name" | awk -F : {'print $2'} | xargs)

# Network
IP_ADDR=$(nslookup $HOSTNAME | grep -A2 $HOSTNAME | grep Address | awk -F : {'print $2'} | xargs)
ILO_VAR="ilo -ilo an -an am -am imm -imm an-rsa rsa -rsa aan -aan rb -rb -rd -mn mn"

# Process
MAN_PRO="mysql websphere weblogic jboss tws"
ROOT_PRO="srm tripwire BESClient phi hippa splunkd cirba hpsmhd TaniumClient cma vasd"

# Create necessary directory for logs 
if [ ! -d /var/log/ddlog ]; then
        mkdir -p /var/log/ddlog
fi

# syslog
LOGFILE=/var/log/ddlog/script.log
ERRORFILE=/var/log/ddlog/errors.log
WARNFILE=/var/log/ddlog/warning.log
FAILFILE=/var/log/ddlog/failed.log
PASSFILE=/var/log/ddlog/passed.log

##############################################################
write_header()
{
echo -e "\t\t\t\t\t\t<b>$@</b>"
echo "-------------------------------------------------------------------------------------------------------------"
}

write_subheader()
{
echo -e "<b>$@</b>"
echo "--------------------------------------"
}
##############################################################

gen_info()
{
        echo -e "<center><address>$TIME_STAMP</address></center>"
        echo -e "<center><address>Origin: $SOURCE</address></center>"
echo "<center>-------------------------------------------------------------------------------------------------------------</center>"
}


##############################################################
chk_hostname()
{
HOSTNAME=`hostname`
        if [[ "$HOSTNAME" > "0" ]]; then
	echo "<pre>"
        echo -e "$(passed)\t\tConfigured Hostname\t\t=\t$HOSTNAME"
else
        echo -e "$(warning)\t\tHostname is not configured"
	echo "</pre>"
fi
}
##############################################################
chk_distro()
{
if [[ -r /etc/redhat-release ]]; then
        DIST=`awk -F' ' '{print $1 " "$2 " "$3 " "$4 " "$5}' /etc/redhat-release`
        RELEASE=`awk -F' ' '{print $7}' /etc/redhat-release`
        echo -e "$(passed)\t\tDistribution\t\t\t=\t${DIST} ${RELEASE}"
else
        echo -e "$(failed)\t\tYour OS / OS Release is not supported.";
exit 1
fi
}
##############################################################
chk_ip()
{
	if [[ "$IP_ADDR" > "0" ]]; then
	echo -e "$(passed)\t\tIP Address\t\t\t=\t$IP_ADDR"
else
        echo -e "$(warning)\t\tIP Address\t\t\t=\tUnable to find IP address "
fi
}
##############################################################
chk_sl()
{
	if [[ "$SL_NO" > "0" ]]; then
	echo -e "$(passed)\t\tSerial Number\t\t\t=\t$SL_NO"
else
        echo -e "$(warning)\t\tSerial Number\t\t\t=\tUnable to find Serial Number "
fi
}
##############################################################
chk_sys_man()
{
	if [[ "$SYS_MAN" > "0" ]]; then
        echo -e "$(passed)\t\tSystem Manufacturer\t\t=\t$SYS_MAN"
else
        echo -e "$(warning)\t\tSystem Manufacturer\t\t=\tUnable to find System Manufacturer "
fi
}
##############################################################
chk_sys_model()
{
	if [[ "$SYS_MODEL" > "0" ]]; then
        echo -e "$(passed)\t\tSystem Model\t\t\t=\t$SYS_MODEL"
else
        echo -e "$(warning)\t\tSystem Model\t\t\t=\tUnable to find System Model"
fi
}
##############################################################
chk_uptime()
{
uptime=$(</proc/uptime)
uptime=${uptime%%.*}
seconds=$(( uptime%60 ))
minutes=$(( uptime/60%60 ))
hours=$(( uptime/60/60%24 ))
days=$(( uptime/60/60/24 ))
echo -e "$(passed)\t\tUptime\t\t\t\t=\t$days days, $hours hours, $minutes minutes, $seconds seconds"
}
##############################################################
chk_vm_phy()
{
SYSTEM=`dmidecode -t system | grep -i product | cut -d " " -f3`
case $SYSTEM in
    KVM )       echo -e "$(passed)\t\t$HOSTNAME\t\t=\tVM running on KVM."
        ;;
    VMware ) echo -e "$(passed)\t\t$HOSTNAME\t\t=\tVM running on ESX Server."
        ;;
    * ) echo -e "$(passed)\t\t$HOSTNAME\t\t=\tRunning on a PHYSICAL box."
        ;;
esac
}
##############################################################
chk_ilo()
{
SYS_HOSTNAME=$(uname -n | awk -F. '{print $1}')
for v in $ILO_VAR
do
VIP_OUT=`nslookup $SYS_HOSTNAME$v | grep -A1 Name | grep -i Address | awk -F : {'print $2'} | xargs`
for k in $VIP_OUT
do
PING_RESULT=$(ping -q -W 3 -c 2 "${k}"); PING_RC="$?"
if [[ "${PING_RC}" = "0" ]]; then
     	echo -e "$(passed)\t\tIMM/ILO IP\t\t\t=\t$k"
else
        echo -e "$(info)\t\tIMM/ILO IP\t\t\t=\t$k is not accessible" 
fi
done
done
}
##############################################################
chk_users()
{
echo ""
write_header "List of users logged in and activity"
LIST_USER=`/usr/bin/w`
 if [[ "$LIST_USER" != "" ]]; then
        echo -e "$(info)\t\tList of users logged in and activity"
	echo
	echo "$LIST_USER"
else
	echo
        echo -e "$(warning)\t\tUnable to find users list "
fi
}

##############################################################
chk_fstype()
{
echo ""
write_header "File System Details"
echo
FS_TYPE=`mount | egrep '^/dev' | awk '{print $5}' | sort -u | uniq | xargs`
FS_INFO=`mount | egrep '^/dev' | egrep -iv 'cdrom|proc|pts' | awk '{print $1 " " $3 " " $5}'`
case $FS_TYPE in
    ext3 )   echo -e "$(passed)\t\tFile System Type\t\t=\t$FS_TYPE"
#            echo
#            echo "$FS_INFO"
        ;;
    ext4 )   echo -e "$(passed)\t\tFile System Type\t\t=\t$FS_TYPE"
#            echo
#            echo "$FS_INFO"    
        ;;
    xfs )    echo -e "$(passed)\t\tFile System Type\t\t=\t$FS_TYPE"
#            echo 
#            echo "$FS_INFO"
        ;;
    * )      echo -e "$(passed)\t\tFile System Type\t\t=\t$FS_TYPE"
#            echo
#            echo "$FS_INFO"    
        ;;
esac
}

##############################################################

chk_clus_fs()
{
echo ""
write_header "Clustered/Database File System Details"
ora_pro="$(ps -ef | grep pmon | grep -v grep)"
ora1=`echo $?`

## asm disks
if [ "$ora1" = 0 ]; then
asm_pro="$(ps -ef | grep pmon | grep asm | grep -v grep)"
	if [ "$?" = "0" ]; then
		echo -e "$(info)\t\t\tOracle ASM Disk Found"		
	else
		echo -e "$(passed)\t\tOracle ASM Disk not Found"
	fi
else
	echo -e "$(passed)\t\tOracle ASM Disk not found"
fi

## ocfs2 and gfs2 file system
FSV="ocfs2 gfs2"
for i in $FSV;do
if [ -f /etc/init.d/$i ]; then
fss_pro="$(/etc/init.d/$i status)"
	if [ "$?" = "0" ]; then
		echo -e "$(info)\t\t$i Found"		
	else
		echo -e "$(passed)\t\t$i not Found"
	fi
else
echo -e "$(passed)\t\t$i not Found"
fi
done
}
##############################################################

chk_clus_ser()
{
echo ""
write_header "Cluster Services Information"
## Oracle RAC Cluster
ora_clus="$(ps -ef | grep -i crs | grep -v grep)"
	if [ "$?" = "0" ]; then
		echo -e "$(failed)\t\tOracle RAC Cluster is running"		
	else
		echo -e "$(passed)\t\tOracle RAC Cluster is not running"
	fi
## Redhat Cluster
if [ -f "/etc/cluster/cluster.conf" ]; then
red_clus="$(/etc/init.d/cman status)"
	if [ "$?" = "0" ]; then
		echo -e "$(failed)\t\tRedhat Cluster is running"		
	else
		echo -e "$(passed)\t\tRedhat Cluster is not running"
	fi
else
	echo -e "$(passed)\t\tRedhat Cluster not found"
fi

## veritas Cluster
if [ -d "/etc/VRTSvcs" ]; then
ver_clus="$(ps -ef | grep -i had | grep -v grep)"
if [ "$?" = "0" ]; then
		echo -e "$(failed)\t\tVeritas Cluster is running"		
	else
		echo -e "$(passed)\t\tVeritas Cluster is not running"
	fi
else
	echo -e "$(passed)\t\tVeritas Cluster not Found"
fi
echo
}

##############################################################
chk_app_db_pro()
{
JAVA_PRO="java jre" 
echo
write_header "Details of Non root App/DB process"
for p in $MAN_PRO
do
ps -ef | grep $p | grep -v grep > /dev/null
  if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess $p is running."
  else
        echo -e "$(passed)\t\tProcess $p is not running."
  fi
done

http_PRO="$(/etc/init.d/httpd status)"
if [ $? -eq 0 ]; then
        echo -e "$(info)\t\tProcess httpd is running."
  else
        echo -e "$(info)\t\tProcess httpd is not running."
  fi

DB2_PRO="$(ps -ef | grep db2sys | egrep -v 'avahi|ssh' | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess db2 is running."
  else
        echo -e "$(passed)\t\tProcess db2 is not running."
  fi

ORA_PRO1="$(ps -ef | grep java | grep oracle | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess Oracle is running."        
  else
        echo -e "$(passed)\t\tProcess Oracle is not running."
  fi

ORA_PRO="$(ps -ef | grep pmon | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess OracleDB is running."        
  else
        echo -e "$(passed)\t\tProcess OracleDB is not running."
  fi

APACHETOMCAT_PRO="$(ps -ef | grep -E "apache|tomcat" | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess apache/tomcat is running."        
  else
        echo -e "$(passed)\t\tProcess apache/tomcat is not running."
  fi

IPLANET_PRO="$(ps -ef | grep -E "webservd|iplanet" | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess iplanet is running."        
  else
        echo -e "$(passed)\t\tProcess iplanet is not running."
  fi

IBM_DIR_PRO="$(ps -ef | grep director | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(info)\t\tProcess jre (IBM Director) is running."        
  else
        echo -e "$(passed)\t\tProcess jre (IBM Director) is not running."
  fi

## JAVA PROCESS

ps -ef | grep java | grep -v root | grep -v grep > /dev/null
  if [ $? -eq 0 ]; then
        echo -e "$(failed)\t\tProcess Java is running."        
  else
        echo -e "$(passed)\t\tProcess Java is not running."
  fi
}
##############################################################
chk_backup_tool()
{
echo 
write_header "Checking Backup Tools"
if [ -d "/opt/tivoli/tsm" ]; then
TSM_STAT="$(ps -ef | grep dsmcad | grep -v grep)"
        if [ "$?" = "0" ]; then
                echo -e "$(info)\t\tTSM is running"                
        else
                echo -e "$(passed)\t\tTSM is not running"
        fi
else
        echo -e "$(info)\t\tTSM not found"
fi

NET_BACKUP="$(ps -ef | egrep 'vnetd|bpcd' | grep -v grep)"
if [ $? -eq 0 ]; then
        echo -e "$(info)\t\tNetbackup Tool is running."        
  else
        echo -e "$(passed)\t\tNetbackup Tool is not running."
  fi
}
##############################################################
chk_san_disk()
{
EMC=`rpm -qa | grep EMC`
EPID=`pgrep emcp`
LUNS=`powermt display dev=all|grep "Logical"|wc -l`
SAN=`/usr/bin/lsscsi | grep EMC | awk -F " " {'print $3'} | uniq`
echo
write_header "Checking SAN Availability"
if  [ "$SAN" = EMC ]; then
	echo -e "$(info)\t\tSAN Found."
#	echo "`/usr/bin/lsscsi`"
else
	echo -e "$(passed)\t\tSAN not Found."
#	echo "`/usr/bin/lsscsi`"
fi

## Checking EMC service
if [ "$EMC" > 0 ]; then
	if [ -n "$EPID" ]; then
		  echo -e "$(info)\t\tEMC PowerPath service is running."
        else
                  echo -e "$(info)\t\tEMC PowerPath service is not running."
		  exit 1
        fi

## Checking WWPN Numbers
	if ( which systool >/dev/null 2>&1 ); then
		echo -e "$(info)\t\tFound wwpn Numbers."
		echo
		     systool -c fc_host -v | grep port_name | awk -F " " {'print $3'}
	else
		echo -e "$(info)\t\tWWPN Numbers not found"
	fi

else
	echo -e "$(passed)\t\tEMC PowerPath is Not Installed"
	exit
fi
}
##############################################################
chk_nfs_mount()
{
NFS_EXP="$(cat /etc/exports | grep -v "#")"
echo ""
write_header "Details of NFS mounts"
NFS_MNT="$(mount | grep nfs | egrep -v 'sunrpc|nfsd')"
        if [ "$?" = "0" ]; then
                echo -e "$(info)\t\tFound NFS mounts"
                echo "`mount | grep nfs | egrep -v 'sunrpc|nfsd'`"
        else
		echo -e "$(passed)\t\tNot Found NFS mounts"
	fi
## NFS Export
	if [[ "$NFS_EXP" != "" ]];then
		echo -e "$(info)\t\tFound NFS Shares exported to outside"
                echo "`cat /etc/exports | grep -v "#"`"
        else
                echo -e "$(passed)\t\tNot Found NFS Shares exported to outside"
        fi
}
##############################################################
chk_network_info()
{
write_header "Network Information"
echo ""
SYSCLASS=$(ifconfig | grep Link | awk '{print $1}' | egrep -v "lo|usb" | xargs)
for j in $SYSCLASS
do
IFCONFIG_INFO=`ifconfig $j |grep -i "inet addr" |awk -F : '{print $2}'|awk '{print $1}' | xargs`
for i in $IFCONFIG_INFO
 do
 HOSTLIST=`grep $i /etc/hosts | awk '{print $2}' | awk -F "." '{print $1}'`
 if [ $? -eq 0 ];then
 case $HOSTLIST in
    "$HOST"    )       echo -e "$(passed)\t\tPrimary IP\t\t=\t$i"
        ;;
    "$HOST"vip )       echo -e "$(passed)\t\tVirtual IP\t\t=\t$i"
        ;;
    "$HOST"priv)       echo -e "$(passed)\t\tPrivate IP\t\t=\t$i"
        ;;
    "$HOST"-priv)      echo -e "$(passed)\t\tPrivate IP\t\t=\t$i"
        ;;
            * )       NLP=$(nslookup $i | grep "name =" | awk '{print $4}' | awk -F "." '{print $1}')
                      if [ "$NLP" == "$HOST"e ] ||[ "$NLP" == "$HOST"-e ] || [ "$NLP" == "$HOST"e1 ] || [ "$NLP" == "$HOST"-e1 ]|| [ "$NLP" == "$HOST"bk ]|| [ "$NLP" == "$HOST"-bk ];then
                        echo -e "$(passed)\t\tBackup IP\t\t=\t$i"
                      elif [ "$NLP" == "$HOST"vip ] ||[ "$NLP" == "$HOST"-vip ]; then
                        echo -e "$(passed)\t\tVirtual IP\t\t=\t$i"
		      elif [ "$NLP" == "$HOST" ]; then
                        echo -e "$(passed)\t\tPrimary IP\t\t=\t$i"
		      elif [ "$NLP" == scan-"$HOST" ] || [ "$NLP" == scan"$HOST" ] || [ "$NLP" == "$HOST"-scan ] || [ "$NLP" == "$HOST"scan ]; then
                        echo -e "$(passed)\t\t\tscan IP\t\t=\t$i"
                      else
                        echo -e "$(info)\t\tUnknown IP\t\t=\t$i"
                      fi
        ;;
 esac
 else
 echo -e "$(warning)\t\tUnable to find IP address"
 fi
 done
done
}

##############################################################
chk_static_route()
{
echo
write_subheader "static routes if present"
NSL_OP="$(nslookup $HOST | grep -A2 Name | grep Address | awk -F : '{print $2}' | sed 's/[0-9]*$/1/'| xargs)"
ROUTE_INFO="$(netstat -nr | awk {'print $2'}  | egrep -v 'IP|Gateway|0.0.0.0' | uniq)"
echo "Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface"
for i in $ROUTE_INFO
do
if [ $NSL_OP = "$i" ]; then
echo "" > /dev/null
else
netstat -nr | grep $i
fi
done
}

##############################################################
chk_ip_resolve()
{
echo
write_subheader "Resolving IP Details"
HO=`ifconfig | grep -i "inet addr" |awk -F : '{print $2}'|awk '{print $1}' |grep -v "127.0.0.1" && sed 's/#//g' /etc/hosts | awk {'print $1'} | egrep -v "127.0.0.1|::1"`
new_var=`echo "$HO"|sort|uniq|xargs`
for k in $new_var
do
RSNLP=$(nslookup $k | grep "name =" | awk '{print $4}' | awk '{print $1}')
if [ "$RSNLP" != "" ];
then
echo "$k = $RSNLP"
else
echo "Not resolving" > /dev/null
fi
done
}

##############################################################
chk_root_pro()
{
echo
write_header "Details of root owned process"
for k in $ROOT_PRO
do
ps -ef | grep $k | grep -v grep > /dev/null
  if [ $? -eq 0 ]; then
        echo -e "$(info)\t\tProcess $k is running."
  else
        echo -e "$(passed)\t\tProcess $k is not running."
  fi
done

TIV_PRO="$(/usr/Tivoli/ITM/bin/cinfo -r | egrep '08|lz')"
if [ $? -eq 0 ]; then
        echo -e "$(info)\t\tProcess Tivoli is running."
  else
        echo -e "$(passed)\t\tProcess Tivoli is not running."
  fi

}

##############################################################
chk_nonroot_pro()
{
echo
write_header "Details of non-root process if any running"
NUD=`w | awk {'print $1'} | sed -n '$p'`
ps -ef | grep -v root | egrep -v '^[0-9]|postfix|ntp|vasd|rpc|dbus|avahi|smmsp|daemon' | grep -v $NUD
}

##############################################################

gen_notes()
{
echo ""
write_header
echo -e "<font size="4" color="blue"> <b>INFO:- </font> </b>"
echo -ne "<font size="3" color="red"> <b>1. Verify the serial number with remedy.\n 2. Verify the IMM/ILO console access for physical server.\n 3. Verify the server GACDW CI status (Should not be sunset). </font> </b>"
}

##############################################################

system_info()
{
echo "<h1>System Information</h1>"
        chk_hostname
        chk_distro
        chk_ip
	chk_sl
        chk_sys_man
        chk_uptime
	chk_sys_model
        chk_vm_phy
	chk_ilo
        echo
}   # end of System Information

##############################################################
users_info()
{
	echo 
	chk_users
	echo
}  # end of user Information

##############################################################

mount_disk_info()
{
	echo 
	chk_fstype
	chk_clus_fs
	echo
}  # end of file system information
##############################################################

cluster_info()
{
	echo 
	chk_clus_ser
	echo
}  # end of cluster information
##############################################################

app_db_process()
{
	echo 
	chk_app_db_pro
	echo
}  # end of app-db information
##############################################################
backup_tool_info()
{
	echo 
	chk_backup_tool
	echo
}  # end of backup_tools information
##############################################################
san_disk_info()
{
	echo 
	chk_san_disk
	echo
}  # end of san_disk information
##############################################################
nfs_mount_info()
{
	echo 
	chk_nfs_mount
	echo
}  # end of nfs_mount information
##############################################################
network_info()
{
	echo 
	chk_network_info
	chk_ip_resolve
	chk_static_route
	echo
}  # end of Network information
##############################################################
root_nonroot_pro()
{
	echo 
	chk_root_pro
	chk_nonroot_pro
	gen_notes
	echo
}  # end of root and non-root app information
##############################################################
# Logging the script
# Clean existing log files
# Implement log rotation - WORK TO BE DONE ...............................
if [ -f "$LOGFILE" ]
then
rm -f $LOGFILE $ERRORFILE $WARNFILE $PASSFILE $FAILFILE
else
touch $LOGFILE $ERRORFILE $WARNFILE $PASSFILE $FAILFILE
fi
exec 2> $ERRORFILE

##############################################################
write_html()
{
    cat <<- _EOF_
    <!DOCTYPE html>
    <html>
        <head>
        <title>$TITLE</title>
        </head>
        <body>
        <center><h1>$TITLE</h1></center> 
        $(gen_info)
        $(system_info)
	$(users_info)
        $(mount_disk_info)
	$(cluster_info)
	$(app_db_process)
	$(backup_tool_info)
        $(san_disk_info)
        $(nfs_mount_info)
        $(network_info)
        $(root_nonroot_pro)
        </body>
    </html>
_EOF_
}

##############################################################

filename=/tmp/dd_report_$HOST-`date +"%F-%I:%M%p"`.html
echo
echo "Report File = $filename"

# Generate HTML file
write_html > $filename

grep -i PASSED $filename >$PASSFILE
grep -i FAILED $filename >$FAILFILE
grep -i WARNING $filename >$WARNFILE
echo 
echo "Logs dumped to '/var/log/ddlog/' directory."
echo
# END of script
exit
