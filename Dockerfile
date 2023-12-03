FROM public.ecr.aws/debian/debian:trixie
LABEL maintainer="Vasudevan Perumal"

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies.
RUN cat /etc/apt/sources.list.d/*
# To get access to the ubuntu-keyring package
RUN echo "deb http://ftp.de.debian.org/debian sid main" >> /etc/apt/sources.list
RUN apt update
# RUN apt upgrade -y
# RUN apt install -y --fix-broken libreadline8
RUN apt install --fix-broken --yes --no-install-recommends \
       build-essential \
       bubblewrap \
       cpio \
       curl \
       dosfstools \
       e2fsprogs \
       git \
       iproute2 \
       procps \
       python3-apt \
       python3-dev \
       python3-pip \
       python3-setuptools \
       python3-venv \
       python3-wheel \
       sudo \
       squashfs-tools \
       systemd \
       systemd-boot \
       systemd-sysv \
       mtools \
       ubuntu-keyring \
       zstd \
    && rm --force --recursive /var/lib/apt/lists/* \
    && rm --force --recursive /usr/share/doc \
    && rm --force --recursive /usr/share/man \
    && apt clean


WORKDIR /root/image_build


COPY definitions/ /root/image_build/

RUN chmod 600 mkosi.rootpw

# Allow installing stuff to system Python.
RUN rm --force /usr/lib/python3.11/EXTERNALLY-MANAGED
RUN pip3 install --upgrade pip
RUN pip3 install pefile

RUN python3 -m venv mkosivenv
RUN mkosivenv/bin/pip install git+https://github.com/systemd/mkosi.git
RUN mkosivenv/bin/mkosi --version

ENTRYPOINT ["/usr/bin/bash"]
# CMD mkosivenv/bin/mkosi -f
