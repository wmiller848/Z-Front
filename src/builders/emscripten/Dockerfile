###
###
FROM fedora:22

RUN dnf -y update
RUN dnf -y install make cmake automake gcc gcc-c++ kernel-devel yasm
RUN dnf -y install git tar wget

########
## Java
########
WORKDIR /opt/vendor
RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz"
RUN tar -xzf jdk-8u45-linux-x64.tar.gz

ENV JAVA_HOME=/opt/jdk1.8.0_45
ENV JRE_HOME=/opt/jdk1.8.0_45/jre
ENV PATH=$PATH:/opt/jdk1.8.0_45/bin:/opt/jdk1.8.0_45/jre/bin

##########
## Nodejs
##########
WORKDIR /opt/vendor
RUN wget http://nodejs.org/dist/v0.12.3/node-v0.12.3.tar.gz
RUN tar -xvf node-v0.12.3.tar.gz

WORKDIR /opt/vendor/node-v0.12.3

RUN ./configure
RUN make install

##############
## Emscripten
##############
WORKDIR /opt/vendor
RUN wget https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz
RUN tar -xvf emsdk-portable.tar.gz

WORKDIR /opt/vendor/emsdk_portable

RUN ./emsdk update
RUN ./emsdk install latest
RUN ./emsdk activate latest

# RUN source emsdk_env.sh
ENV PATH=$PATH:/opt/vendor/emsdk_portable
ENV PATH=$PATH:/opt/vendor/emsdk_portable/clang/tag-e1.34.10/build_tag-e1.34.10_64/bin
ENV PATH=$PATH:/opt/vendor/emsdk_portable/emscripten/tag-1.34.10
ENV EMSCRIPTEN=/opt/vendor/emsdk_portable/emscripten/tag-1.34.10

CMD /bin/bash -l
