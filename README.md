# Dockerfile for an OpenStreetMap Tile Server

This Dockerfile creates an OSM tile server based on the instructions from https://switch2osm.org/manually-building-a-tile-server-16-04-2-lts/.

## Building

```
git clone https://github.com/rooch84/docker-osm-tile-server.git osm
cd osm
docker build -t osm:1.0 .
```

### Arguments

The following arguments can be modified using the --build-args flag.

 - `OSM_USER=renderaccount`
 - `DATA=http://download.geofabrik.de/asia/azerbaijan-latest.osm.pbf`
 - `OSM2PGSQL_RAM=2000`
 - `OSM2PGSQL_PROCESSES=1`

For example, to populate the map data for Algeria, and process the data using 4 cores and 8GB of RAM, you can use the following command (you may also want to set the tag to the name of the region you're rendering):

`docker build -t osm:algeria --build-arg OSM2PGSQL_RAM=2000 --build-arg OSM2PGSQL_PROCESSES=5 --build-arg DATA=http://download.geofabrik.de/africa/algeria-latest.osm.pbf .`

## Running

To run the newly built container (and access the tile server from port 8008 for example), just run:

`docker run -p 8008:80 osm:1.0`

Assuming the container is running locally, you can then test it works by pointing your browser at (you should see a single tile):

http://localhost:8008/hot/0/0/0.png

## Contributing

Pull requests welcomed.
