FROM ubuntu:trusty

RUN apt-get update -y
RUN apt-get install -y openssl libssl-dev
RUN apt-get install -y wget tar
RUN apt-get install -y build-essential
RUN apt-get install -y sudo make cmake

WORKDIR /opt

RUN wget http://prdownloads.sourceforge.net/ircd-hybrid/ircd-hybrid-8.2.7.tgz

RUN tar -xvf ircd-hybrid-8.2.7.tgz

WORKDIR /opt/ircd-hybrid-8.2.7

RUN ./configure
RUN make install

WORKDIR /opt

RUN wget http://sourceforge.net/projects/anope/files/anope-stable/Anope%202.0.1/anope-2.0.1-source.tar.gz

RUN tar -xvf anope-2.0.1-source.tar.gz

WORKDIR /opt/anope-2.0.1-source/build

ADD ./conf/config.cache /opt/anope-2.0.1-source/config.cache
RUN ../Config -quick
RUN make install

RUN groupadd zfront
RUN useradd -m -g zfront zfront
RUN echo zfront:root | chpasswd

RUN echo "%zfront ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ADD ./conf/ircd.conf /usr/local/etc/ircd.conf

WORKDIR /opt

EXPOSE 6665
EXPOSE 6666
EXPOSE 6667
EXPOSE 6668
EXPOSE 6669

CMD ircd -foreground
