FROM ubuntu:18.04

# Set user
ARG OSM_USER=renderaccount

RUN apt-get update

# Set the locale
RUN apt-get -y install locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

RUN apt-get -y install libboost-all-dev git-core tar unzip wget bzip2 \
    build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev \
    libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev \
    protobuf-c-compiler libfreetype6-dev libpng-dev libtiff5-dev \
    libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 \
    apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev \ 
    libgeotiff-epsg

# Postgres / Postgis

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install postgresql postgresql-contrib postgis \ 
    postgresql-10-postgis-2.4
USER postgres
RUN  /etc/init.d/postgresql start && \
     createuser -s -d -r -e $OSM_USER && \
     createdb -E UTF8 -O $OSM_USER -T template0 gis && \
     psql -d gis -c "CREATE EXTENSION postgis;" && \
     psql -d gis -c "CREATE EXTENSION hstore;" && \
     psql -d gis -c "ALTER TABLE geometry_columns OWNER TO $OSM_USER;" && \
     psql -d gis -c "ALTER TABLE spatial_ref_sys OWNER TO $OSM_USER;"

USER root
RUN useradd -m $OSM_USER

# osm2pgsql

USER root
RUN apt-get -y install make cmake g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev \ 
    libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev

USER $OSM_USER
RUN mkdir ~/src && \
    cd ~/src && \
    git clone https://github.com/openstreetmap/osm2pgsql.git && \
    cd ~/src/osm2pgsql && \
    mkdir ~/src/osm2pgsql/build && cd ~/src/osm2pgsql/build && \
    cmake .. && \
    make
USER root
RUN cd /home/$OSM_USER/src/osm2pgsql/build && make install

# Mapnik

USER root
RUN apt-get -y install autoconf apache2-dev libtool libxml2-dev libbz2-dev \ 
    libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal-dev libmapnik-dev \
    mapnik-utils python-mapnik

# mod_tile and renderd

USER $OSM_USER
RUN cd ~/src && \
    git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git && \
    cd mod_tile && \
    ./autogen.sh && \
    ./configure && \
    make
USER root
RUN cd /home/$OSM_USER/src/mod_tile && \
    make install && \
    make install-mod_tile && \
    ldconfig

# Stylesheet
USER root
RUN apt-get -y install npm nodejs
RUN npm -v
RUN npm install -g carto

USER $OSM_USER
RUN cd ~/src && \
    git clone https://github.com/gravitystorm/openstreetmap-carto.git && \
    cd openstreetmap-carto && \
    carto -v && \
    carto project.mml > mapnik.xml

# Map data
ARG DATA=http://download.geofabrik.de/asia/azerbaijan-latest.osm.pbf
USER $OSM_USER
RUN mkdir ~/data && \
    cd ~/data && \
    wget $DATA

ARG OSM2PGSQL_RAM=2000
ARG OSM2PGSQL_PROCESSES=1
USER root
RUN  file=$(echo "$DATA" | sed "s/.*\///") && \
     /etc/init.d/postgresql start && su $OSM_USER -c "osm2pgsql -d gis \
    --create --slim  -G --hstore --tag-transform-script \
    ~/src/openstreetmap-carto/openstreetmap-carto.lua \
    -C $OSM2PGSQL_RAM --number-processes $OSM2PGSQL_PROCESSES \
    -S ~/src/openstreetmap-carto/openstreetmap-carto.style \
    ~/data/$file"

# Shapefile

USER $OSM_USER 
RUN cd ~/src/openstreetmap-carto/ && \
    scripts/get-shapefiles.py

# Fonts

USER root
RUN apt-get -y install fonts-noto-cjk fonts-noto-hinted \
    fonts-noto-unhinted ttf-unifont

# Apache config
USER root 
RUN mkdir /var/lib/mod_tile
RUN chown $OSM_USER /var/lib/mod_tile
RUN mkdir /var/run/renderd
RUN chown $OSM_USER /var/run/renderd

RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> \ 
    /etc/apache2/conf-available/mod_tile.conf
RUN a2enconf mod_tile

ADD ./conf/apache_default.conf /etc/apache2/sites-available/000-default.conf
ADD ./scripts/init.sh /bin/init.sh

RUN chmod a+x /bin/init.sh

ENTRYPOINT [ "sh", "-c", "/bin/init.sh" ] 
