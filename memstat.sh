#!/bin/bash
LOG_FILE=/var/log/memory_status.log
printf '=%.0s' {1..27} >> $LOG_FILE
echo -e "\n=== $(date +%d/%m/%Y" "%T) ===" >> $LOG_FILE
printf '=%.0s' {1..27} >> $LOG_FILE
echo -e "\n\nUPTIME:" >> $LOG_FILE
uptime >> $LOG_FILE
echo -e "\nMEM USAGE:" >> $LOG_FILE
head -n 3 /proc/meminfo >> $LOG_FILE
echo -e "\nTOP 30 PROCESSES:" >> $LOG_FILE
ps -eo pmem,pid,comm | sort -r | head -n 31 >> $LOG_FILE

