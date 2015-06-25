#
FROM zfront/nginx:latest

ADD ./conf/zfront /usr/local/nginx/conf/zfront
ADD ./conf/nginx.conf /usr/local/nginx/conf/nginx.conf

RUN mkdir -p /tmp/stream
