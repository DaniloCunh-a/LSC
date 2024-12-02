#!/bin/sh
#
# Start the network....
#

# Inicia a OTG-USB via Serial com teminal interativo
mkdir -p /run/network

case "$1" in
  start)
	modprobe g_serial
        setsid getty -L -l /bin/sh -n 115200 /dev/ttyGS0

	;;
  stop)
	printf "Stopping..."
	
#TODO
	;;
  restart|reload)
	"$0" stop
	"$0" start
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?

