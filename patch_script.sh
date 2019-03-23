#!/bin/bash
# version: Initial
# Created by Jyothish & Praful K G   - Kadaster Unix team - 5-November-2018
# Script to deploy Linux patches in Kadaster Environment
USERNAME=`/usr/bin/whoami`
HOSTS=~/hosts.txt
YUM_CONFIG_FILE="/etc/yum.repos.d/rhel6-update-latest.repo"
today_date=$(date +'%m-%d-%Y')

yum_config () {
COPY_YUM_CONFIG="/usr/bin/sudo cp ${HOME}/rhel6-update-latest.repo /etc/yum.repos.d/rhel6-update-latest.repo"
        for server in `cat ${HOSTS}` ; do
                echo "Modifying yum configuration on $server"
                scp -q -o "BatchMode yes" -o StrictHostKeyChecking=no ${YUM_CONFIG_FILE} ${server}:${HOME}
                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} "${COPY_YUM_CONFIG}"
                        if [ $? -ne 0 ] ; then
                                echo "Yum configuration modification failed on $server. Fix connection issues and retry."
                        fi
        done
}

pre_check () {
PRE_CHECK="uptime > pre-uptime; cat /etc/redhat-release > pre-redhat-release ; uname -a > pre-uname ; df -hP > pre-df ; cat pre-df | wc -l > pre-df.wc ; /usr/bin/sudo /bin/mount > pre-mount ; cat pre-mount | wc -l > pre-mount.wc ; free -m > pre-memory; netstat -rn > pre-route ; /sbin/ip addr > pre-ipaddr ; /usr/bin/sudo /sbin/service --status-all|grep is\ running | cut -d ' ' -f 1  > pre-service ; /usr/bin/sudo /sbin/pvs > pre-pvinfo ; /usr/bin/sudo /sbin/vgs > pre-vginfo ; /usr/bin/sudo /sbin/lvs > pre-lvinfo ; cat pre-pvinfo | wc -l > pre-pvinfo.wc ; cat pre-vginfo | wc -l > pre-vginfo.wc ; cat pre-lvinfo | wc -l > pre-lvinfo.wc ; ps -ef | grep -v root > pre-non-root-services"
echo "This will perform prechecks on all servers and collect output at http://10.21.16.100/patch/pre_check"
if [ ! -d /var/www/html/patch/pre_check/${today_date} ]; then
find /var/www/html/patch/pre_check/* -type d -ctime +30 -exec rm -rf {} \; > /dev/null 2>&1
mkdir -p /var/www/html/patch/pre_check/${today_date}
else
echo "today date is available" > /dev/null
fi
        for server in `cat ${HOSTS}` ; do
                echo "Performing pre-checks on $server"
                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} "${PRE_CHECK}" > /dev/null 2>&1
                        if [ $? -ne 0 ] ; then
                                echo "Pre-checks failed on $server. Fix connection issues and retry."
                                else
                                mkdir -p /var/www/html/patch/pre_check/${today_date}/$server > /dev/null 2>&1
                                scp -q -o "BatchMode yes" -o StrictHostKeyChecking=no ${server}:~/pre-* /var/www/html/patch/pre_check/${today_date}/$server/
                                /bin/chmod o+r /var/www/html/patch/pre_check/${today_date}/$server/*
                        fi
        done
}

test_repo () {
TEST_REPO="/usr/bin/sudo yum clean all > /dev/null 2>&1 ; /usr/bin/sudo yum --enablerepo rhel6-update-latest check-update > ${HOME}/check-update.out 2>&1"
echo "This will execute yum --enablerepo rhel6-update-latest check-update on all servers and collect the output at http://10.21.16.100/patch/test_repo/"
if [ -d /var/www/html/patch/test_repo/${today_date} ]; then
echo "today date is available" > /dev/null
else
find /var/www/html/patch/test_repo/* -type d -ctime +30 -exec rm -rf {} \; > /dev/null 2>&1
mkdir -p /var/www/html/patch/test_repo/${today_date}
fi
        for server in `cat ${HOSTS}` ; do
                echo "Checking the updates on $server"
                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} "${TEST_REPO}"
                        if [ $? -eq 0 ] ; then
                                echo "No packages marked for update on server $server"
                                else
                                scp -q -o "BatchMode yes" -o StrictHostKeyChecking=no ${server}:${HOME}/check-update.out /var/www/html/patch/test_repo/${today_date}/${server}_check-update.out
                                /bin/chmod o+r /var/www/html/patch/test_repo/${today_date}/*
                        fi

        done
}

patch_reboot () {
PATCH="/usr/bin/sudo yum --enablerepo rhel6-update-latest --exclude=java-1.8.0* update -y > ${HOME}/patch.logs 2>&1"
echo "This will install patches on all servers and collect the output at http://10.21.16.100/patch/patch_result/"
if [ -d /var/www/html/patch/patch_result/${today_date} ]; then
echo "today date is available" > /dev/null
else
find /var/www/html/patch/patch_result/* -type d -ctime +30 -exec rm -rf {} \; > /dev/null 2>&1
mkdir -p /var/www/html/patch/patch_result/${today_date}
fi

        for server in `cat ${HOSTS}` ; do
                echo "Performing patching on $server"
                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} "${PATCH}"
                        if [ $? -ne 0 ] ; then
                                echo "Fix connection issues from `hostname` to $server"
                        else
                                scp -q -o "BatchMode yes" -o StrictHostKeyChecking=no ${server}:${HOME}/patch.logs /var/www/html/patch/patch_result/${today_date}/${server}.patch.logs
                                /bin/chmod o+r /var/www/html/patch/patch_result/${today_date}/*
                                tail -n 1 /var/www/html/patch/patch_result/${today_date}/${server}.patch.logs | grep Complete\! > /dev/null 2>&1
                                        if [ $? -ne 0 ] ; then
                                                echo "Patching was not successful on $server. Check http://10.21.16.100/patch/patch_result/$server.patch.logs for details"
                                                else
                                                echo "Rebooting server $server"
                                                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} /usr/bin/sudo /sbin/shutdown -ry now
                                        fi
                        fi
        done
}

post_check () {
POST_CHECK="uptime > post-uptime; cat /etc/redhat-release > post-redhat-release ; uname -a > post-uname ; df -hP > post-df ; cat post-df | wc -l > post-df.wc ; /usr/bin/sudo /bin/mount > post-mount ; cat post-mount | wc -l > post-mount.wc ; free -m > post-memory; netstat -rn > post-route ; /sbin/ip addr > post-ipaddr ; /usr/bin/sudo /sbin/service --status-all|grep is\ running | cut -d ' ' -f 1  > post-service ; /usr/bin/sudo /sbin/pvs > post-pvinfo ; /usr/bin/sudo /sbin/vgs > post-vginfo ; /usr/bin/sudo /sbin/lvs > post-lvinfo ; cat post-pvinfo | wc -l > post-pvinfo.wc ; cat post-vginfo | wc -l > post-vginfo.wc ; cat post-lvinfo | wc -l > post-lvinfo.wc ; ps -ef | grep -v root > post-non-root-services"
echo "This will perform post checks on all servers and collect output at http://10.21.16.100/patch/post_check"
if [ -d /var/www/html/patch/post_check/${today_date} ]; then
echo "today date is available" > /dev/null
else
find /var/www/html/patch/post_check/* -type d -ctime +30 -exec rm -rf {} \; > /dev/null 2>&1
mkdir -p /var/www/html/patch/post_check/${today_date}
fi
        for server in `cat ${HOSTS}` ; do
                echo "Performing post checks on $server"
                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} "${POST_CHECK}" > /dev/null 2>&1
                        if [ $? -ne 0 ] ; then
                                echo "Post checks failed on $server"
                        else
                        mkdir /var/www/html/patch/post_check/${today_date}/$server > /dev/null 2>&1
                        scp -q -o "BatchMode yes" -o StrictHostKeyChecking=no ${server}:~/post-* /var/www/html/patch/post_check/${today_date}/$server/
                        /bin/chmod o+r /var/www/html/patch/post_check/${today_date}/$server/*
                        fi
        done
}

compare () {
COMPARE="/usr/bin/comm -3 pre-redhat-release post-redhat-release > comp-redhat-release ; /usr/bin/comm -3 pre-uname post-uname > comp-uname ; /usr/bin/comm -3 pre-df.wc post-df.wc > comp-df.wc ; /usr/bin/comm -3 pre-mount.wc post-mount.wc > comp-mount.wc ; /usr/bin/comm -3 pre-route post-route > comp-route ; /usr/bin/comm -3 pre-ipaddr post-ipaddr > comp-ipaddr ; /usr/bin/comm -3 pre-service post-service > comp-service ; /usr/bin/comm -3 pre-pvinfo.wc post-pvinfo.wc > comp-pvinfo.wc ; /usr/bin/comm -3 pre-vginfo.wc post-vginfo.wc > comp-vginfo.wc ; /usr/bin/comm -3 pre-lvinfo.wc post-lvinfo.wc > comp-lvinfo.wc"
echo "This will perform the comparison between post check and pre checks and collect output at http://10.21.16.100/patch/compare"
if [ -d /var/www/html/patch/compare/${today_date} ]; then
echo "today date is available" > /dev/null
else
find /var/www/html/patch/compare/* -type d -ctime +30 -exec rm -rf {} \; > /dev/null 2>&1
mkdir -p /var/www/html/patch/compare/${today_date}
fi

        for server in `cat ${HOSTS}` ; do
                echo "Performing comparison between pre and post checks on $server"
                ssh -q -o "BatchMode yes" -o StrictHostKeyChecking=no -l ${USERNAME} ${server} "${COMPARE}"
                        if [ $? -ne 0 ] ; then
                                echo "Comparison failed on $server. Fix connection issue and retry."
                                else
                                mkdir /var/www/html/patch/compare/${today_date}/$server > /dev/null 2>&1
                                scp -q -o "BatchMode yes" -o StrictHostKeyChecking=no ${server}:~/comp-* /var/www/html/patch/compare/${today_date}/$server/
                               /bin/chmod o+r /var/www/html/patch/compare/${today_date}/$server/*
                        fi
        done
}

if [ $USERNAME = "root" ] ; then
                        echo " Run the command with a non root user "
                        exit 1
fi

if [ ! -f ~/hosts.txt ] ; then
        echo "Hostlist file does not exists. Create file hosts.txt in the users home directory with the list of servers"
        exit 1
fi

clear
        while :
        do
                clear
                        echo ""
                        echo ""
                        echo "                      PATCH AUTOMATION TOOL FOR KADASTER REDHAT LINUX SERVERS"
                        echo ""
                        echo " 1. Deploy yum configuration file -  $YUM_CONFIG_FILE"
                        echo ""
                        echo " 2. Perform pre checks"
                        echo ""
                        echo " 3. Validate repository and updates"
                        echo ""
                        echo " 4. Perform patching and reboot"
                        echo ""
                        echo " 5. Perform post checks"
                        echo ""
                        echo " 6. Compare Pre and Post checks"
                        echo ""
                        echo " 7. Exit"
                        echo ""
                        echo -n " Enter the action number which you want to perform : "
                read opt
                case $opt in
                        1)
                        yum_config
                        exit;;
                        2)
                        pre_check
                        exit;;
                        3)
                        test_repo
                        exit;;
                        4)
                        patch_reboot
                        exit;;
                        5)
                        post_check
                        exit;;
                        6)
                        compare
                        exit;;
                        7)
                        exit;;
                        *)
                        echo "$opt is no a valid option"
                        echo "Press [enter] key to continue ..."
                        read enterKey
                        ;;
                esac
        done

