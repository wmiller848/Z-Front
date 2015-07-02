###
###
FROM zfront/emscripten:latest

RUN yum -y update
RUN yum -y install glibc-static bzip2 fontconfig

RUN npm install -g gulp phantomjs

WORKDIR /opt/vendor
RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=https%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz"

RUN tar -xvf jdk-8u45-linux-x64.tar.gz
RUN rm jdk-8u45-linux-x64.tar.gz

ENV JAVA_HOME=/opt/vendor/jdk1.8.0_45
ENV JRE_HOME=/opt/vendor/jdk1.8.0_45/jre
ENV PATH=$PATH:/opt/vendor/jdk-8u45-linux-x64/bin:/opt/vendor/jdk1.8.0_45/jre/bin

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

WORKDIR /opt/zcoderz/js

RUN npm install
RUN gulp

CMD bash -l
