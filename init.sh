#!/bin/sh -e
# MetOcean Status startup script
#chkconfig: 2345 80 05
#description: MetOceanStatus

case "$1" in
  # Start command
  start)
    echo "Starting Status"
    /bin/sh -c 'cd /var/www/status.metocean.co.nz && echo $$ > /tmp/status.pid && exec node server.js >& /dev/null' &
    ;;
  # Stop command
  stop)
    echo "Stopping Status"
    kill -9 $(cat /tmp/status.pid)
    rm -f /tmp/status.pid
    echo "Status stopped successfully"
    ;;
   # Restart command
   restart)
	$0 stop
        sleep 5
        $0 start
        ;;
  *)
    echo "Usage: service metoceanstatus {start|restart|stop}"
    exit 1
    ;;
esac

exit 0