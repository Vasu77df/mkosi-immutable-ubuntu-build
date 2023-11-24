FROM debian:unstable
LABEL maintainer="Vasudevan Perumal"

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
       build-essential \
       cpio \
       curl \
       dosfstools \
       e2fsprogs \
       git \
       iproute2 \
       libffi-dev \
       libssl-dev \
       procps \
       python3-apt \
       python3-dev \
       python3-pip \
       python3-setuptools \
       python3-wheel \
       sudo \
       squashfs-tools \
       systemd \
       systemd-boot \
       systemd-sysv \
       mkosi \
       mtools \
       ubuntu-keyring \
       zstd \
    && rm --force --recursive /var/lib/apt/lists/* \
    && rm --force --recursive /usr/share/doc \
    && rm --force --recursive /usr/share/man \
    && apt-get clean


WORKDIR /root/mkosi

RUN git clone https://github.com/Vasu77df/mkosi-immutable-ubuntu-build.git

WORKDIR /root/mkosi/mkosi-immutable-ubuntu-build
RUN chmod 600 mkosi.rootpw

# Allow installing stuff to system Python.
RUN rm --force /usr/lib/python3.11/EXTERNALLY-MANAGED
RUN pip3 install --upgrade pip
RUN pip3 install pefile

# quick check if I have access to mirrors locally before I kick of the generic image build
CMD mkosi
