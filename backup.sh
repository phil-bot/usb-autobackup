#!/bin/bash

function logger() {
    printf '%s %s' "$(date)" "${@}"
}

# CONFIG
SERVER=nas.lan
SOURCE_DIR=${SERVER}:/mnt/nvme
TARGET_DIR=/mnt/backup
MOUNT_POINT=/dev/disk/by-label/Backup

urlOfUpdatedVersion="https://raw.githubusercontent.com/phil-bot/usb-autobackup/master/backup.sh"
existingScriptLocation="$(realpath "$0")"
tempScriptLocation=$(mktemp)

echo -----------------------------------------------------

# Online Check
logger 'Wait for github.com...'
until curl -s -f -o /dev/null "https://github.com"
do
  sleep 5
  printf '.'
done
printf 'reachable.\n'

# Download the online version to a temporary location
wget -q -O "$tempScriptLocation" "$urlOfUpdatedVersion"

# Update Check
if cmp --silent -- "$existingScriptLocation" "$tempScriptLocation"; then
    logger 'No script update needed.\n'
else
    # Replace the current script with the updated version
    if [[ -f "$tempScriptLocation" ]]; then
        mv "$tempScriptLocation" "$existingScriptLocation"
        chmod +x "$existingScriptLocation"
        logger 'Script updated successfully.'\n
        UPDATED=true
        exec $existingScriptLocation
    else
        logger 'Failed to download the updated script.\n'
        rm $tempScriptLocation
        exit 1
    fi
fi

# Get Location
logger 'Get location: '
ORT=$(curl -s https://ipinfo.io/city)
POSTAL=$(curl -s https://ipinfo.io/postal)

printf '%s (%s)\n' "${ORT}" "${POSTAL}"

# Check for Server
logger 'Wait for %s...' "${SERVER}"
while ! ping -c 1 -n -w 1 ${SERVER} &> /dev/null
do
    #waiting..
    sleep 5
    printf '.'
    # VPN CONNECTION
    printf "Connect to VPN... "
    /usr/bin/nmcli con up id wg0

done
printf 'reachable.\n'

ICH="Backup\-RaspberryPi in ${ORT} \(${POSTAL}\)"

if [[ $UPDATED == true ]]; then
    /usr/bin/telegram-send -M "*${ICH} updated successfully* (Version: ${Version}). \U0001f680"
fi

logger "umount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR}

logger "create ${TARGET_DIR}..."
/usr/bin/mkdir -p ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKann den Einhängepunkt nicht erstellen\."; exit; }

logger "mount ${TARGET_DIR}"
/usr/bin/mount ${MOUNT_POINT} ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nFestplatte nicht gefunden\.\."; exit; }

sleep 3

/usr/bin/telegram-send -M "*${ICH} meldet sich zum Dienst* \U0001f596 \n\nVerbindung mit *${SERVER//./\\.}* erfolgreich hergestellt\.\n\nBackup wird jetzt gestartet\."

logger "start rsync..."

SECONDS=0

/usr/bin/rsync -a --delete "${SOURCE_DIR}/" "${TARGET_DIR}" || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKopiervorgang nicht erfolgreich\."; exit; }

duration=$SECONDS

logger "rsync done..."

sleep 3

logger "umount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKonnte die Festplatte nicht aushängen\."; exit; }
/usr/bin/telegram-send -M "*${ICH} hat das Backup erfolgreich beendet* \U0001F64C \n\nGedauert hat das ganze $((duration / 60)) Minuten\.\n\nIch lege mich wieder Schlafen\."
sleep 5

##echo shutdown.. bye bye..
logger "put HD to sleep"
hdparm -y /dev/sda

logger "disconnect from VPN"
/usr/bin/nmcli con down id wg0

#shutdown now
