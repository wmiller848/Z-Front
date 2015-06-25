#

ffmpeg -y -i ./swfa.mp4 -vcodec libvpx -r 24 -b:v 4096k -acodec libvorbis -b:a 128k swfa_vp8_vorbis.webm

ffmpeg -y -i ./swfa.mp4 -vcodec libvpx-vp9 -r 24 -b:v 2048k -acodec libvorbis -b:a 128k swfa_vp9_vorbis.webm

ffmpeg -y -re -i rtmp://127.0.0.1:1935/stream/12345 -vcodec libvpx-vp9 -r 24 -b:v 2048k -acodec libvorbis -b:a 128k /tmp/streaming/12345.webm

ffmpeg -y -i ./swfa.mp4 -vcodec libtheora -r 24 -b:v 4096k -acodec libvorbis -b:a 128k swfa_theora_vorbis.ogv

ffmpeg -y -i ./swfa.mp4 -vcodec libx264 -r 24 -b:v 2048k -acodec copy swfa_h264_aac.mp4

ffmpeg -y -i ./swfa.mp4 -vcodec libx265 -r 24 -b:v 2048k -acodec copy swfa_h265_aac.mp4

ffmpeg -y -i ./swfa.mp4 -vcodec libvpx -r 24 -b:v 2048k -acodec libvorbis -f mpegts udp://192.168.0.1:20999

ffmpeg -re -i ./swfa.mp4 -vcodec libvpx -r 24 -b:v 1024k -reset_timestamps 1 -map 0 -acodec libvorbis -b:a 64k -f segment ./test/out%d.webm
