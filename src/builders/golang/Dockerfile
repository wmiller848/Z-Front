#
FROM fedora:latest

# Set up deps
RUN yum install -y glibc-devel glibc-headers glibc-static
RUN yum install -y gcc cpp hostname
RUN yum install -y openssl-devel
RUN yum install -y git mercurial

# Install golang
WORKDIR /opt
RUN git clone https://github.com/golang/go.git
WORKDIR /opt/go/src
RUN git checkout release-branch.go1.4
RUN ./all.bash
RUN mkdir /opt/golang
ENV GOPATH=/opt/golang
ENV PATH=$PATH:/opt/go/bin:$GOPATH/bin
RUN go get golang.org/x/tools/cmd/...
WORKDIR /opt
