# A whoogle-search instance in a docker container

Informations here: [whoogle github project](https://github.com/benbusby/whoogle-search.git)

## Howto

The image is based on python:3.11.0a1-alpine3.14

The container is monitored by supervisor, because there is two processes to launch:

* tor is launched
* and whoogle, with the `./run` command.

To keep configuration parameters, you can use a named volume or a local bind (ie `"${PWD}"`):

```
docker run --name whatever \
           -p "5000":"host_port" \
           -v whoogle_volume:/home/whoogle/config:rw \
           aexerces/whoogle-instance
```

## Raspberry PI

Just launch the command to build the image on a Rpi (only tested on mine, a Raspberry Pi 4 Model B, 4Gb RAM, ubuntu server 20.04):

```
docker build -t the_image_name .
``` 

## Note

There is no exposed ports because I'm using caddy server as a reverse proxy, for HTTPS, see example folder.

The whoogle app itself is accessible on the port 5000.

