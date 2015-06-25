# WWW Container #

FROM `market/nginx:latest`

This service boots up the web site.

## Commands ##

### Build ###
This command will build the web site container.

`./build`

### Run ###
This command will run the web site container, binding to the default http/https ports and any other ports exposed in the image.

`./run`

### Stop ###
This command will stop the web site container.

`./stop`

## Docker ##
`docker ps` to view running containers
