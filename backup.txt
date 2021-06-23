#!/bin/bash

# Ask the user for backup details

read -p 'Enter number of days to findout the older files: ' days
read -p 'Enter the backup location: ' bkp_path
read -p 'Enter the country name: ' cn

# Define Variables

file_name_pega="Pega_Case_Data"
src_path_pega="/data/share/gsxxfe/prpc/outbox/$cn/Extract/Daily"
file_name_kyc="KYCAnalystActionData"
src_path_kyc="/data/share/gsxxfe/prpc/outbox/$cn/Extract/Daily"

# create a folder in /tmp to create a list of files  which need to be moved

mkdir -p /tmp/archive/$cn
file_path="/tmp/archive/$cn"

read -p "Do you want to start archive for $file_name_pega [y/n]: " archive

if [[ $archive == 'y' ]]
then

# Clear file path

if [ -d "$file_path" ]
then
        echo -n > $file_path/total_pega_files_archived 2>/dev/null
fi

# find Pega_Case_Data files older than x days
echo "***** Finding $file_name_pega files older than $days days from the location $src_path_pega....Please wait"
find $src_path_pega -type f -mtime +$days -name "$file_name_pega*" -printf '%f\n' > $file_path/$file_name_pega
total_files_pega=`cat $file_path/$file_name_pega | wc -l`
echo "Total no of files found for archive: `cat $file_path/$file_name_pega | wc -l`" &> $file_path/total_pega_files_before_archive

# Backup process for Pega_Case_Data
if [ -d "$bkp_path" ]
then
        echo "******Start Archive process for $file_name_pega *******"
        mkdir -p $bkp_path/$cn/$file_name_pega
        full_bkp_path="$bkp_path/$cn/$file_name_pega"
        for i in `cat $file_path/$file_name_pega`;
                do
                        mv -v $src_path_pega/$i $full_bkp_path >> $file_path/total_pega_files_archived 2>> $file_path/pega_files_archive_err
                done
        echo "Archive process is completed for $file_name_pega"
        cat $file_path/total_pega_files_before_archive
        echo "Total no of files moved to archived location: `cat $file_path/total_pega_files_archived | wc -l`"
else
        echo "Backup folder $bkp_path does not exist !!!"
fi
else
        echo "Archive process not started for $file_name_pega... Quiting !"
fi

read -p "Do you want to start archive for $file_name_kyc [y/n]: " archive

if [[ $archive == 'y' ]]
then

# Clear file path

if [ -d "$file_path" ]
then
        echo -n > $file_path/total_kyc_analyst_files_archived 2>/dev/null
fi

# find KYCAnalystActionData files older than x days
echo "***** Finding $file_name_kyc files older than $days days from the location $src_path_kyc....Please wait"
find $src_path_kyc -type f -mtime +$days -name "$file_name_kyc*" -printf '%f\n' > $file_path/$file_name_kyc
total_files_kyc=`cat $file_path/$file_name_kyc | wc -l`
echo "Total no of files found for archive: `cat $file_path/$file_name_kyc | wc -l`" &> $file_path/total_kyc_analyst_files_before_archive

# Backup process for KYCAnalystActionData
if [ -d "$bkp_path" ]
then
        echo "******Start Archive process for $file_name_kyc *******"
        mkdir -p $bkp_path/$cn/$file_name_kyc
        full_bkp_path="$bkp_path/$cn/$file_name_kyc"
        for i in `cat $file_path/$file_name_kyc`;
                do
                        mv -v $src_path_kyc/$i $full_bkp_path >> $file_path/total_kyc_analyst_files_archived 2>> $file_path/kyc_analyst_files_archive_err
                done
        echo "Archive process is completed for $file_name_kyc"
        cat $file_path/total_kyc_analyst_files_before_archive
        echo "Total no of files moved to archived location: `cat $file_path/total_kyc_analyst_files_archived | wc -l`"
else
        echo "Backup folder $bkp_path does not exist !!!"
fi
else
        echo "Archive process not started for $file_name_kyc... Quiting !"
fi
