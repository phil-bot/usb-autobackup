install:
	install -v -o root -g root -m 644 00-usb-device.rules /etc/udev/rules.d
	install -v -o root -g root backup.sh /root
	install -v -o root -g root -m 644 autobackup.service /etc/systemd/system
