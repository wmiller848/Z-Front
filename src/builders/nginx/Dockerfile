#
FROM fedora:latest

# Set up deps
RUN yum install -y glibc-devel glibc-headers glibc-static
RUN yum install -y gcc gcc-c++ cpp pcre-devel
RUN yum install -y openssl-devel zlib-devel
RUN yum install -y git mercurial
RUN yum install -y tar wget
RUN yum install -y cmake make autoconf pkgconfig
RUN yum install -y libtool nasm
RUN yum install -y freetype*

# Install ffmpeg
WORKDIR /opt/vendor
RUN git clone git://github.com/yasm/yasm.git
WORKDIR /opt/vendor/yasm
RUN autoreconf -fiv
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --bindir="/bin"
RUN make install

WORKDIR /opt/vendor
RUN git clone git://git.videolan.org/x264
WORKDIR /opt/vendor/x264
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --bindir="/bin" --enable-static
RUN make install

WORKDIR /opt/vendor
RUN hg clone https://bitbucket.org/multicoreware/x265
WORKDIR /opt/vendor/x265/build/linux
RUN cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/opt/vendor/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
RUN make install

WORKDIR /opt/vendor
RUN git clone git://git.code.sf.net/p/opencore-amr/fdk-aac
WORKDIR /opt/vendor/fdk-aac
RUN autoreconf -fiv
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --disable-shared
RUN make install

WORKDIR /opt/vendor
RUN wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
RUN tar -xzvf lame-3.99.5.tar.gz
WORKDIR /opt/vendor/lame-3.99.5
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --bindir="/bin" --disable-shared --enable-nasm
RUN make install

WORKDIR /opt/vendor
RUN git clone git://git.opus-codec.org/opus.git
WORKDIR /opt/vendor/opus
RUN autoreconf -fiv
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --disable-shared
RUN make install

WORKDIR /opt/vendor
RUN wget http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
RUN tar -xzvf libogg-1.3.2.tar.gz
WORKDIR /opt/vendor/libogg-1.3.2
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --disable-shared
RUN make install

WORKDIR /opt/vendor
RUN wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
RUN tar -xzvf libvorbis-1.3.4.tar.gz
WORKDIR /opt/vendor/libvorbis-1.3.4
RUN LDFLAGS="-L/opt/vendor/ffmeg_build/lib" CPPFLAGS="-I/opt/vendor/ffmpeg_build/include"\
    ./configure --prefix="/opt/vendor/ffmpeg_build" --with-ogg="/opt/vendor/ffmpeg_build"\
    --disable-shared
RUN make install

WORKDIR /opt/vendor
RUN git clone https://chromium.googlesource.com/webm/libvpx.git
WORKDIR /opt/vendor/libvpx
RUN ./configure --prefix="/opt/vendor/ffmpeg_build" --disable-examples
RUN make install

WORKDIR /opt/vendor
RUN git clone git://source.ffmpeg.org/ffmpeg
WORKDIR /opt/vendor/ffmpeg
RUN PKG_CONFIG_PATH="/usr/lib/pkgconfig:/opt/vendor/ffmpeg_build/lib/pkgconfig" ./configure\
    --prefix="/opt/vendor/ffmpeg_build" --extra-cflags="-I/opt/vendor/ffmpeg_build/include"\
    --extra-ldflags="-L/opt/vendor/ffmpeg_build/lib" --bindir="/bin"\
    --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-libfdk_aac\
    --enable-libmp3lame --enable-libopus --enable-libvorbis\
    --enable-libvpx --enable-libx264 --enable-libx265
RUN make install
RUN hash -r

# Download nginx and rtmp module
WORKDIR /opt/vendor
RUN wget http://nginx.org/download/nginx-1.9.0.tar.gz
RUN git clone https://github.com/arut/nginx-rtmp-module.git
RUN tar -xvpzf nginx-1.9.0.tar.gz

# Install nginx
WORKDIR /opt/vendor/nginx-1.9.0
RUN ./configure --with-http_spdy_module --with-http_ssl_module\
  --with-http_addition_module --with-http_sub_module\
  --with-http_auth_request_module\
  --with-http_secure_link_module --with-http_gzip_static_module\
  --with-http_gunzip_module --with-mail --with-mail_ssl_module\
  --with-http_flv_module --with-http_mp4_module\
  --add-module=/opt/vendor/nginx-rtmp-module
RUN make install
WORKDIR /opt

EXPOSE 80
EXPOSE 443
EXPOSE 8080

CMD /usr/local/nginx/sbin/nginx
