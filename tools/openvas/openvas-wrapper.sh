#!/bin/bash

# (c) 2014-2019 Mattias Schlenker for LessLinux

ask_for_quit() {
	task="$1"
	echo -n "${task} failed - continue anyway? [y/N] "
	read continue
	case "$continue" in 
		[yYjJ]*)
			echo 'OK, continue...'
		;;
		*)
			echo "${task} failed - exiting."
			exit 1
		;;
	esac
}

me=` id -u `
if [ "$me" -gt 0 ] ; then
        echo 'Please run this script with root privileges!'
fi

if mountpoint -q /lesslinux/blobpart ; then
	echo '/lesslinux/blobpart is mounted, great...'
else
	echo 'WARNING: You are currently running from memory!'
	echo ''
	echo 'OpenVAS large collection of vulnerability tests needs more than 1.5GB space.'
	echo 'You might continue if you have at least 6GB of RAM. If you have less main'
	echo 'memory or wish to keep the data persistent, please read the notes on creating'
	echo 'a bootable USB thumb drive or a thumb drive just containing OpenVAS data.'
	echo ''
	echo 'More information: http://blog.lesslinux.org/openvas-included/'
	echo ''
	ask_for_quit "BLOB partition"
fi

ruby /usr/share/lesslinux/drivetools/waitservice.rb openvas 

greenbone-nvt-sync || greenbone-nvt-sync
retval=$?
[ "$retval" -gt 0 ] && ask_for_quit "Syncing NVT"

greenbone-scapdata-sync || greenbone-scapdata-sync
retval=$?
[ "$retval" -gt 0 ] && ask_for_quit "Syncing Scapdata"

greenbone-certdata-sync || greenbone-certdata-sync
retval=$?
[ "$retval" -gt 0 ] && ask_for_quit "Syncing Certdata"

# Write config
mkdir -p /etc/openvas
cat > /etc/openvas/redis.conf <<EOF
daemonize yes
bind 127.0.0.1
unixsocket /tmp/redis.sock
unixsocketperm 700
EOF

redis-server /etc/openvas/redis.conf


# Start the scan daemon
openvassd 
sleep 1
plist=`ps waux  | awk '{print $11}' ` 
if echo "$plist" | grep openvassd ; then
	echo "Successfully started openvassd"
else
	echo "Starting openvassd"
	openvassd
	sleep 1
fi

# Rebuild the database
# test -f /usr/var/lib/openvas/mgr/tasks.db || openvasmd --rebuild
echo 'Rebuilding the database - this might take some time!'
openvasmd --rebuild --progress
openvasmd --create-user=lesslinux --role=Admin
openvasmd --user=lesslinux --new-password=lesslinux
sleep 1
openvasmd 
sleep 1
plist=`ps waux  | awk '{print $11}' ` 
if echo "$plist" | grep openvasmd ; then
	echo "Successfully started openvasmd"
else
	echo "Starting openvasmd"
	openvasmd 
	sleep 1
fi

gsad --http-only --listen=127.0.0.1  -p 9392 start

echo 'Starting Firefox - login with username "lesslinux" and password "lesslinux"!'
zenity --info --text 'Starting Firefox - login with username "lesslinux" and password "lesslinux"!'

nohup su surfer -c 'firefox http://127.0.0.1:9392/' &
sleep 3
