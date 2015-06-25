#
FROM fedora:latest

RUN yum install -y glibc-devel glibc-headers glibc-static
RUN yum install -y gcc cpp
RUN yum install -y git mercurial
RUN yum install -y wget tar

WORKDIR /opt
RUN wget https://static.rust-lang.org/rustup.sh
RUN chmod +x ./rustup.sh
RUN ./rustup.sh --verbose --yes --disable-sudo

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
