 /etc/init.d/postgresql start
service apache2 start
echo -n "Waiting for postgres to start."
until `pg_isready -q`; do
  echo -n "."  
  sleep 1
done
su - renderaccount -c "renderd -f -c /usr/local/etc/renderd.conf"
