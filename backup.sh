#!/bin/bash

# eventuell vpn...

SERVER=n3.grothu.lan

echo "waiting for ${SERVER}"
while ! ping -c 1 -n -w 1 ${SERVER} &> /dev/null
do
    echo ".."
done
echo "${SERVER} is online" | /usr/bin/telegram-send


# Define your source and target directories
SOURCE_DIR=${SERVER}:/mnt/nvme
TARGET_DIR=/mnt/backup
MOUNT_POINT=/dev/disk/by-label/BackupA

/usr/bin/mkdir -p ${TARGET_DIR}
# Uncomment this if you need to mount the drive first. This assumes that you've
# defined your mount point in /etc/fstab. Otherwise, you'll need to expand this
# command to include the device.
/usr/bin/mount ${MOUNT_POINT} ${TARGET_DIR}
# Write a log message so we can see from the logs that this has started
#echo "backup device mounted" | /usr/bin/telegram-send

# If you want to send yourself an email when the backup starts, uncomment this
# line and add your email address. You'll need a working `mail` command.
echo "Starting backup at $(date +%H:%M:%S)" | /usr/bin/telegram-send

# Do the backup with rsync or whatever you want. You'll probably want to
# customize this for your system
/usr/bin/rsync -a --delete "${SOURCE_DIR}/" "${TARGET_DIR}"

sleep 3

# Unmount the device
/usr/bin/umount ${TARGET_DIR}

# Write a log message so we can see from the logs that this has finished
#echo "backup device unmounted" | /usr/bin/telegram-send

# If you want to send yourself an email when the backup finishes, uncomment this
# line and add your email address. You'll need a working `mail` command.
echo "Finished backup at $(date +%H:%M:%S)" | /usr/bin/telegram-send


#shutdown now
