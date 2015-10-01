# WWW Container #

FROM `market/nginx:latest`

This service boots up the web site.

### FFMPEG ##

libvpx
libvpx-vp9

Wide 2160p (HD 4k)
ffmpeg -threads 0 -i swfa.mp4 -r 25 -c:v libvpx-vp9 -b:v 2300k -s 5120×2160 -aspect 21:9 swfa_out.ivf

2160p (HD 4k)
ffmpeg -threads 0 -i swfa.mp4 -r 25 -c:v libvpx-vp9 -b:v 1800k -s 3840×2160 -aspect 16:9 swfa_out.ivf

1080p (HD)
ffmpeg -threads 0 -i swfa.mp4 -r 25 -c:v libvpx-vp9 -b:v 1200k -s 1920x1080 -aspect 16:9 swfa_out.ivf

720p (HD)
ffmpeg -threads 0 -i swfa.mp4 -r 25 -c:v libvpx-vp9 -b:v 700k -s 1280x720 -aspect 16:9 swfa_out.ivf
ffmpeg -threads 0 -i swfa.mp4 -c:v libvpx-vp9 -quality realtime -cpu-used 4 -b:v 800k -bufsize 1600k -qmin 10 -qmax 42 -vf scale=-1:720 swfa_out.ivf

Wide 480p (SD)
ffmpeg -threads 0 -i swfa.mp4 -r 25 -c:v libvpx-vp9 -b:v 300k -s 720x480 -aspect 16:9 swfa_out.ivf

480p (SD)
ffmpeg -threads 0 -i swfa.mp4 -r 25 -c:v libvpx-vp9 -b:v 200k -s 640x480 -aspect 4:3 swfa_out.ivf
ffmpeg -threads 0 -i swfa.mp4 -c:v libvpx-vp9 -b:v 200k -s 640x480 -aspect 4:3 swfa_out.ivf

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
