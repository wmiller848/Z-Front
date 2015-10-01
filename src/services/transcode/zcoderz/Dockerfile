###
###
FROM zfront/emscripten:latest

RUN dnf -y install libtool glibc-static bzip2 fontconfig which

RUN npm install -g gulp phantomjs

WORKDIR /opt/vendor

ENV JAVA_HOME=/opt/vendor/jdk1.8.0_45
ENV JRE_HOME=/opt/vendor/jdk1.8.0_45/jre
ENV PATH=$PATH:/opt/vendor/jdk1.8.0_45/bin:/opt/jdk1.8.0_45/jre/bin

##########
## Libvpx
##########
WORKDIR /opt/vendor
RUN wget http://downloads.sourceforge.net/project/check/check/0.9.14/check-0.9.14.tar.gz

#RUN git clone https://github.com/webmproject/libvpx.git
#RUN git clone https://github.com/wmiller848/libvpx.git
ADD ./libvpx /opt/vendor/libvpx

RUN find /opt/vendor/libvpx -exec touch {} \;
RUN ls -la /opt/vendor/libvpx

WORKDIR /opt/vendor/libvpx
#RUN git checkout v1.4.0
RUN git checkout vpx_streams

# This syntax makes emscripten unhappy
RUN sed -i "s/\-rus/rus/" build/make/configure.sh
RUN extra_cflags="-s USE_PTHREADS=1 -s PTHREAD_POOL_SIZE=4" emconfigure ./configure\
#				--prefix=/usr
#				--disable-examples --disable-docs\
				--disable-unit-tests\
				--disable-vp8-encoder --disable-vp9-encoder --disable-vp10-encoder\
				--disable-runtime-cpu-detect\
#				--disable-optimizations\
#				--disable-multithread\
				--enable-error-concealment --enable-postproc\
				--enable-coefficient-range-checking\
#				--enable-realtime-only --enable-onthefly-bitpacking\
				--target=generic-gnu
RUN emmake make -j7

# Replace these functions names to a name spaced version
RUN sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/ivfdec.c;\
		sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/ivfdec.c;\
		sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/ivfdec.c;\
		sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/ivfdec.c;\
		sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/tools_common.h;\
		sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/tools_common.h;\
		sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/tools_common.h;\
		sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/tools_common.h;\
		sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/tools_common.c;\
		sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/tools_common.c;\
		sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/tools_common.c;\
		sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/tools_common.c;\
		sed -i "s/die(/proc_die(/" /opt/vendor/libvpx/video_reader.c;\
		sed -i "s/fatal(/proc_fatal(/" /opt/vendor/libvpx/video_reader.c;\
		sed -i "s/warn(/proc_warn(/" /opt/vendor/libvpx/video_reader.c;\
		sed -i "s/info(/proc_info(/" /opt/vendor/libvpx/video_reader.c

#########
## Libyuv
#########

WORKDIR /opt/vendor
RUN git clone https://github.com/wmiller848/libyuv
WORKDIR /opt/vendor/libyuv
RUN emmake make -j7 V=1 -f linux.mk

#########
## Libopus
#########

WORKDIR /opt/vendor
#RUN git clone git://git.opus-codec.org/opus.git libopus
RUN wget http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz
RUN tar -xf opus-1.1.tar.gz
RUN mv opus-1.1 libopus
WORKDIR /opt/vendor/libopus
#RUN ./autogen.sh
RUN emconfigure ./configure --enable-static=true --enable-shared=false --enable-float-approx
RUN emmake make

ADD ./src /opt/zcoderz

WORKDIR /opt/zcoderz/c

RUN make javascript
#RUN make testNative

WORKDIR /opt/zcoderz/js

RUN npm install
RUN gulp

CMD bash -l
