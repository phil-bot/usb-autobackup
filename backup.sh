#!/bin/bash

function update {
    urlOfUpdatedVersion="https://raw.githubusercontent.com/phil-bot/usb-autobackup/refs/heads/master/backup.sh"
    existingScriptLocation="$(realpath "$0")"
    tempScriptLocation="/tmp/backup.sh"

    # Download the updated version to a temporary location
    wget -q -O "$tempScriptLocation" "$urlOfUpdatedVersion"

    # Replace the current script with the updated version
    if [[ -f "$tempScriptLocation" ]]; then
        mv "$tempScriptLocation" "$existingScriptLocation"
        chmod +x "$existingScriptLocation"
        echo "Script updated successfully." | /usr/bin/telegram-send

        # Optionally, you can run the updated script
        exec "$existingScriptLocation"
    else
        echo "Failed to download the updated script." | /usr/bin/telegram-send
        exit 1
    fi
}

if [[ "$1" == "--update" ]]; then
    update
    exit 0
fi

SERVER=nas.lan

#!/bin/bash

# CONFIG
printf 'wait for heise.de .'
until curl -s -f -o /dev/null "https://heise.de"
do
  sleep 5
  printf '.'
done
printf ' reachable...\n'

echo ----------------------------------------------------------------------
printf 'get location...\n'
ORT=$(curl https://ipinfo.io/city)
POSTAL=$(curl https://ipinfo.io/postal)

printf '\nlocation: %s (%s)\n' "${ORT}" "${POSTAL}"

SERVER=nas.lan

SOURCE_DIR=${SERVER}:/mnt/nvme
TARGET_DIR=/mnt/backup
MOUNT_POINT=/dev/disk/by-label/Backup


# VPN CONNECTION
echo ----------------------------------------------------------------------
echo "connect to vpn..."
#/usr/bin/nmcli c up 'Wired connection 1'
#/usr/bin/nmcli c up VPN
#/usr/bin/nmcli c
/usr/bin/nmcli con up id wg0
echo ----------------------------------------------------------------------
printf 'wait for %s .' "${SERVER}"
while ! ping -c 1 -n -w 1 ${SERVER} &> /dev/null
do
        #waiting..
        sleep 5
        printf '.'
done
printf ' reachable...\n'

ICH="Backup\-RaspberryPi in ${ORT} \(${POSTAL}\)"
echo ----------------------------------------------------------------------
echo "unmount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR}

echo ----------------------------------------------------------------------
echo "create ${TARGET_DIR}..."
/usr/bin/mkdir -p ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKann den Einhängepunkt nicht erstellen\."; exit; }

echo ----------------------------------------------------------------------
echo "mount ${TARGET_DIR}"
/usr/bin/mount ${MOUNT_POINT} ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nFestplatte nicht gefunden\.\."; exit; }

sleep 3

/usr/bin/telegram-send -M "*${ICH} meldet sich zum Dienst* \U0001f596 \n\nVerbindung mit *${SERVER//./\\.}* erfolgreich hergestellt\.\n\nBackup wird jetzt gestartet\.\n\>

echo ----------------------------------------------------------------------
echo "start rsync..."

SECONDS=0

/usr/bin/rsync -a --delete "${SOURCE_DIR}/" "${TARGET_DIR}" || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKopiervorgang nicht erfolgreich\.">

duration=$SECONDS

echo ----------------------------------------------------------------------
echo "rsync done..."

sleep 3

echo ----------------------------------------------------------------------
echo "umount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKonnte die Festplatte nicht aushängen\."; exit; }

/usr/bin/telegram-send -M "*${ICH} hat das Backup erfolgreich beendet* \U0001F64C \n\nGedauert hat das ganze $((duration / 60)) Minuten\.\n\nIch lege mich wieder Schlafe>

sleep 5

echo ----------------------------------------------------------------------
##echo shutdown.. bye bye..

#shutdown now
