#!/bin/bash

#A Single location to specify the storage to test

#Names of files (or devices) to be tested
FILEARRAY=(fileA fileB fileC fileD)
NUMFILES=${#FILEARRAY[@]}
IODEPTHARRAY=( 1 2 4 8 16 32)
NUMIODEPTH=${#IODEPTHARRAY}

WSS_PER_DISK=100M
IOENGINE=sync
IOSIZE_RANDOM=4k
IOSIZE_SEQUENTIAL=1024k
RUNTIME=10s
RUNID=`date +"%y%m%d%H%M"`
mkdir $RUNID

# Create a file "postfix.fio" for each queue depth 
# that will be merged with the template file to create 
#the "global" fio section
for qd in ${IODEPTHARRAY[@]}
do
    # Random Read fio file
    cat /dev/null > postfix.fio
    echo size=$WSS_PER_DISK >> postfix.fio
    echo ioengine=$IOENGINE >> postfix.fio
    echo io_size=$IOSIZE_RANDOM >> postfix.fio
    #iodepth
    echo iodepth=$qd >> postfix.fio
    echo time_based >> postfix.fio
    echo runtime=$RUNTIME >> postfix.fio
    echo group_reporting >> postfix.fio
    echo "" >> postfix.fio
    # Add the per device section of the fio file
    for section in ${FILEARRAY[@]}
    do
        echo "[$section]" >> postfix.fio
        echo filename=$section >>postfix.fio
    done
    #Add this postfix to the boilerplate fio files
    # TODO Add check here that template file exists else fio will blow up
    cat rr.templ postfix.fio > $RUNID/rr-qd$qd.fio
done

#Have the execution as a separate step in case we don't want to run immediately
cd $RUNID
for qd in ${IODEPTHARRAY[@]}
do
 fio rr-qd$qd.fio --output-format=json --output=fio-rr-qd-$qd.out
done