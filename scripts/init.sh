rm -f /usr/local/apache2/logs/httpd.pid


/etc/init.d/postgresql start
echo -n "Waiting for postgres to start."
until `pg_isready -q`; do
  echo -n "."  
  sleep 1
done
service apache2 start
su - renderaccount -c "renderd -f -c /usr/local/etc/renderd.conf"


apachectl -DFOREGROUND
