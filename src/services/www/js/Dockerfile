#
FROM zfront/nginx:latest

ADD ./conf/nginx.conf /usr/local/nginx/conf/nginx.conf
ADD ./src /usr/local/nginx/html

CMD /usr/local/nginx/sbin/nginx
