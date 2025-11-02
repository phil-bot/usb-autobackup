#!/bin/bash


# sudo apt install rsync


# Give a few seconds for the drive to mount if necessary

SERVER=n3.grothu.net

echo "waiting for %s." "${SERVER}"
while ! ping -c 1 -n -w 1 ${SERVER} &> /dev/null
do
    echo ".."
done
echo "${SERVER} is online"


# Define your source and target directories
SOURCE_DIR=${SERVER}:/mnt/nvme
TARGET_DIR=/mnt/backup
MOUNT_POINT=/dev/backup1

/usr/bin/mkdir -p ${TARGET_DIR}
# Uncomment this if you need to mount the drive first. This assumes that you've
# defined your mount point in /etc/fstab. Otherwise, you'll need to expand this
# command to include the device.
/usr/bin/mount ${MOUNT_POINT} ${TARGET_DIR}
# Write a log message so we can see from the logs that this has started
logger "Auto backup device mounted"
/mnt/ssd/config/scripts/telegram-send "Auto backup device mounted"

# If you want to send yourself an email when the backup starts, uncomment this
# line and add your email address. You'll need a working `mail` command.
#echo "Starting backup at $(date +%H:%M:%S)" | mail -s "Backup started on $(hostname)" you@example.com

# Do the backup with rsync or whatever you want. You'll probably want to
# customize this for your system
/usr/bin/rsync -a --delete --dry-run "${SOURCE_DIR}/" "${TARGET_DIR}"

sleep 3

# Unmount the device
/usr/bin/umount ${TARGET_DIR}

# Write a log message so we can see from the logs that this has finished
logger "Auto backup device unmounted"
/mnt/ssd/config/scripts/telegram-send "Auto backup device unmounted"

# If you want to send yourself an email when the backup finishes, uncomment this
# line and add your email address. You'll need a working `mail` command.
#echo "Finished backup at $(date +%H:%M:%S)" | mail -s "Backup finished on $(hostname)" you@example.com


#shutdown now