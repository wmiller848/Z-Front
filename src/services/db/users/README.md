# MySQL Container #

FROM `fedora:latest`

This service/io boots up mysql against a shared data container.

## Commands ##

### Bootstrap ###
This command will build the mysql container and create/override the data volume container.

¡THIS WILL UNREVERSIBLE DELETE SQL DATA!

`./magic bootstrap`

### Start ###
This command will run the mysql container, binding to the default mysql port and any other ports exposed in the image.

`./ magic start`

### Stop ###
This command will stop the mysql container.

`./magic stop`

## Docker ##
`docker ps` to view running containers
