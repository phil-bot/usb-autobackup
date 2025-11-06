#!/bin/bash

Version=0.1.1

function update {
    existingScriptLocation="$(realpath "$0")"
    VersionOnline="$(curl -s https://raw.githubusercontent.com/phil-bot/usb-autobackup/master/backup.sh | grep VERSION)"
    if [[ "${Version}" -ne "${VersionOnline#*=}" ]]
    then
        urlOfUpdatedVersion="https://raw.githubusercontent.com/phil-bot/usb-autobackup/master/backup.sh"

        tempScriptLocation="/tmp/backup.sh"
        # Download the updated version to a temporary location
        wget -q -O "$tempScriptLocation" "$urlOfUpdatedVersion"
        # Replace the current script with the updated version
        if [[ -f "$tempScriptLocation" ]]; then
            mv "$tempScriptLocation" "$existingScriptLocation"
            chmod +x "$existingScriptLocation"
            echo "Script updated successfully."
            UPDATED=true
            echo ----------------------------------------------------------------------

        else
            echo "Failed to download the updated script."
            exit 1
        fi
    fi
    exec "$existingScriptLocation"
}

if [[ "$1" == "--update" ]]; then
    update
    exit 0
fi
exit
# CONFIG
printf 'Wait for heise.de...'
until curl -s -f -o /dev/null "https://heise.de"
do
  sleep 5
  printf '.'
done
printf ' reachable.\n'

echo ----------------------------------------------------------------------
printf 'Get location: '
ORT=$(curl -s https://ipinfo.io/city)
POSTAL=$(curl -s https://ipinfo.io/postal)

printf '%s (%s)\n' "${ORT}" "${POSTAL}"

SERVER=nas.lan

SOURCE_DIR=${SERVER}:/mnt/nvme
TARGET_DIR=/mnt/backup
MOUNT_POINT=/dev/disk/by-label/Backup


# VPN CONNECTION
echo ----------------------------------------------------------------------
printf "Connect to VPN... "
/usr/bin/nmcli con up id wg0
echo ----------------------------------------------------------------------
printf 'Wait for %s...' "${SERVER}"
while ! ping -c 1 -n -w 1 ${SERVER} &> /dev/null
do
        #waiting..
        sleep 5
        printf '.'
done
printf ' reachable.\n'

ICH="Backup\-RaspberryPi in ${ORT} \(${POSTAL}\)"

[[ $UPDATED ]] && { /usr/bin/telegram-send -M "*${ICH} updated successfully* (Version: ${Version}). \U0001f680"; }

echo ----------------------------------------------------------------------
echo "Unmount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR}

echo ----------------------------------------------------------------------
echo "Create ${TARGET_DIR}..."
/usr/bin/mkdir -p ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKann den Einhängepunkt nicht erstellen\."; exit; }

echo ----------------------------------------------------------------------
echo "Mount ${TARGET_DIR}"
/usr/bin/mount ${MOUNT_POINT} ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nFestplatte nicht gefunden\.\."; exit; }

sleep 3

/usr/bin/telegram-send -M "*${ICH} meldet sich zum Dienst* \U0001f596 \n\nVerbindung mit *${SERVER//./\\.}* erfolgreich hergestellt\.\n\nBackup wird jetzt gestartet\."

echo ----------------------------------------------------------------------
echo "Start rsync..."

SECONDS=0

/usr/bin/rsync -a --delete "${SOURCE_DIR}/" "${TARGET_DIR}" || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKopiervorgang nicht erfolgreich\."; exit; }

duration=$SECONDS

echo ----------------------------------------------------------------------
echo "Rsync done..."

sleep 3

echo ----------------------------------------------------------------------
echo "Umount ${TARGET_DIR}"
/usr/bin/umount ${TARGET_DIR} || { /usr/bin/telegram-send -M "*${ICH} meldet einen FEHLER* \U00026A0 \n\nKonnte die Festplatte nicht aushängen\."; exit; }
/usr/bin/telegram-send -M "*${ICH} hat das Backup erfolgreich beendet* \U0001F64C \n\nGedauert hat das ganze $((duration / 60)) Minuten\.\n\nIch lege mich wieder Schlafen\."
sleep 5

echo ----------------------------------------------------------------------

##echo shutdown.. bye bye..
hdparm -y /dev/sda

echo ----------------------------------------------------------------------

/usr/bin/nmcli con down id wg0

#shutdown now
