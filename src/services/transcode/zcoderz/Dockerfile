###
###
FROM zfront/emscripten:latest

RUN yum -y install glibc-static

##########
## Libvpx
##########
WORKDIR /opt/vendor
RUN wget http://downloads.sourceforge.net/project/check/check/0.9.14/check-0.9.14.tar.gz

#RUN git clone https://github.com/webmproject/libvpx.git
#RUN git clone https://github.com/wmiller848/libvpx.git /opt/vendor/libvpx
ADD ./libvpx /opt/vendor/libvpx

RUN ls /opt/vendor/libvpx

WORKDIR /opt/vendor/libvpx
#RUN git checkout v1.4.0
RUN git checkout vpx_streams

# This syntax makes emscripten unhappy
RUN sed -i "s/\-rus/rus/" build/make/configure.sh
RUN emconfigure ./configure\
#				--prefix=/usr
#				--disable-examples --disable-docs\
				--disable-runtime-cpu-detect\
				--disable-multithread --disable-optimizations\
				--target=generic-gnu
RUN emmake make

# Replace these functions names to a name spaced version
RUN sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/ivfdec.c
RUN sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/ivfdec.c
RUN sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/ivfdec.c
RUN sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/ivfdec.c

RUN sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/tools_common.h
RUN sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/tools_common.h
RUN sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/tools_common.h
RUN sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/tools_common.h

RUN sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/tools_common.c
RUN sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/tools_common.c
RUN sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/tools_common.c
RUN sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/tools_common.c

RUN sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/video_reader.c
RUN sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/video_reader.c
RUN sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/video_reader.c
RUN sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/video_reader.c

#RUN ./configure\
#				--prefix=/usr\
#				--disable-examples --disable-docs\
#				--disable-runtime-cpu-detect\
#				--disable-multithread --disable-optimizations
#				--target=generic-gnu
#RUN make

ADD ./src /opt/zcoderz
RUN ls -R /opt/vendor/libvpx

WORKDIR /opt/zcoderz/c

RUN make javascript
#RUN make testNative

CMD bash -l
