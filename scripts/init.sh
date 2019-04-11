# Clear PID files to fix apache restart error
rm -f /usr/local/apache2/logs/httpd.pid

# Clear PID files to fix mod_tile restart error
rm -rf /tmp/*

/etc/init.d/postgresql start
echo -n "Waiting for postgres to start.\n"
until `pg_isready -q`; do
  echo -n "."  
  sleep 1
done
echo -n "Starting rendered...\n"
su - renderaccount -c "renderd -f -c /usr/local/etc/renderd.conf" &
sleep 5
echo -n "Starting apache...\n"
apachectl -D FOREGROUND
