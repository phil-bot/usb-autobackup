#!/bin/bash


# CONFIG
Version="7.11.25"

SERVER=nas.lan
SOURCE_DIR=${SERVER}:/mnt/nvme
TARGET_DIR=/mnt/backup
MOUNT_POINT=/dev/disk/by-label/Backup

urlOfUpdatedVersion="https://raw.githubusercontent.com/phil-bot/usb-autobackup/master/backup.sh"
existingScriptLocation="$(realpath "$0")"
tempScriptLocation=$(mktemp)

date

# Online Check
printf 'Wait for github.com...'
until curl -s -f -o /dev/null "https://github.com"
do
  sleep 5
  printf '.'
done
printf ' reachable.\n'


# Update Check
VersionOnline="$(curl -s ${urlOfUpdatedVersion} | grep Version)"
if [[ "${Version}" != "${VersionOnline#*=}" ]]; then
    
    # Download the updated version to a temporary location
    wget -q -O "$tempScriptLocation" "$urlOfUpdatedVersion"
    # Replace the current script with the updated version
    if [[ -f "$tempScriptLocation" ]]; then
        mv "$tempScriptLocation" "$existingScriptLocation"
        chmod +x "$existingScriptLocation"
        echo "Script updated successfully."
        UPDATED=true
        exec $existingScriptLocation
    else
        echo "Failed to download the updated script."
        exit 1
    fi
fi

# Get Location
printf 'Get location: '
ORT=$(curl -s https://ipinfo.io/city)
POSTAL=$(curl -s https://ipinfo.io/postal)

printf '%s (%s)\n' "${ORT}" "${POSTAL}"


# Check for Server
printf 'Wait for %s...' "${SERVER}"
while ! ping -c 1 -n -w 1 ${SERVER} &> /dev/null
do
    #waiting..
    sleep 5
    printf '.'
    # VPN CONNECTION
    printf "Connect to VPN... "
    /usr/bin/nmcli con up id wg0

done
printf ' reachable.\n'

ICH="Backup\-RaspberryPi in ${ORT} \(${POSTAL}\)"

if [[ $UPDATED == true ]]; then
    /usr/bin/telegram-send -M "*${ICH} updated successfully* (Version: ${Version}). \U0001f680"
fi

echo "umount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR}

echo "create ${TARGET_DIR}..."
/usr/bin/mkdir -p ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKann den Einhängepunkt nicht erstellen\."; exit; }

echo "mount ${TARGET_DIR}"
/usr/bin/mount ${MOUNT_POINT} ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nFestplatte nicht gefunden\.\."; exit; }

sleep 3

/usr/bin/telegram-send -M "*${ICH} meldet sich zum Dienst* \U0001f596 \n\nVerbindung mit *${SERVER//./\\.}* erfolgreich hergestellt\.\n\nBackup wird jetzt gestartet\."

echo "start rsync..."

SECONDS=0

/usr/bin/rsync -a --delete "${SOURCE_DIR}/" "${TARGET_DIR}" || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKopiervorgang nicht erfolgreich\."; exit; }

duration=$SECONDS

echo "rsync done..."

sleep 3

echo "umount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKonnte die Festplatte nicht aushängen\."; exit; }
/usr/bin/telegram-send -M "*${ICH} hat das Backup erfolgreich beendet* \U0001F64C \n\nGedauert hat das ganze $((duration / 60)) Minuten\.\n\nIch lege mich wieder Schlafen\."
sleep 5

##echo shutdown.. bye bye..
hdparm -y /dev/sda

/usr/bin/nmcli con down id wg0

#shutdown now
