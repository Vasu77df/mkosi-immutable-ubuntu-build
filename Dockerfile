<<<<<<< HEAD
FROM public.ecr.aws/docker/library/debian:trixie
LABEL maintainer="Vasudevan Perumal"
=======
FROM public.ecr.aws/docker/library/debian:testing-backports
LABEL maintainer="@vasuper"
>>>>>>> 16b75fc (update build docker image, and latest config sync)

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies.
RUN apt update
RUN apt upgrade -y
# complilers like gcc and gnu debugger
# For when we start compiling systemd and the kernel from source
RUN  apt install -y build-essential 
# sandboxing, and permissions for unprivileged execution used by mkosi
RUN  apt install -y bubblewrap
# for creating cpio archives, used to create initrd and disk images
RUN  apt install -y cpio 
# to maapt install ke call over the network
RUN  apt install -y curl 
# installs commands like mkfs.fat, required to creat a boot partition
RUN  apt install -y dosfstools
# ext fs tools,  to create the rootfs
RUN  apt install -y e2fsprogs 
# pip install mk osi from a git repo
RUN  apt install -y git
# program to manage linux kernel modules
RUN apt install -y kmod
# utilities for /proc  
RUN  apt install -y procps
#  python deps t o get a python project installed
RUN  apt install -y python3-pip
RUN  apt install -y python3-setuptools
RUN  apt install -y python3-venv
RUN  apt install -y python3-wheel
# used apt insta ll to create squashfs rootfs if requested
RUN  apt install -y squashfs-tools
# systeapt insta ll md utilies like
RUN  apt install -y systemd
# utilities to s etup systemd bootloader
RUN  apt install -y systemd-boot
# utiliapt install ty to build an unfied kernel image
RUN apt install -y systemd-ukify
# varioapt install us gpt disk utilities
RUN apt install -y mtools
# gpg kapt install eyring to access ubuntu mirrors
RUN apt install -y ubuntu-keyring
# comprapt install ession library used in building initrd
RUN  apt install -y zstd
# cleanup 
RUN    rm --force --recursive /var/lib/apt/lists/*
RUN    rm --force --recursive /usr/share/doc
RUN    rm --force --recursive /usr/share/man
RUN    apt clean

# the build dir placed to 
WORKDIR /root/build_env

COPY definitions/ /root/build_env

RUN chmod 600 mkosi.rootpw

# Allow installing stuff to system Python.
RUN rm --force /usr/lib/python3.11/EXTERNALLY-MANAGED
RUN pip3 install --upgrade pip
RUN pip3 install pefile

RUN python3 -m venv mkosivenv
RUN mkosivenv/bin/pip install git+https://github.com/systemd/mkosi.git@v20.2
RUN mkosivenv/bin/mkosi --version

ENTRYPOINT ["/usr/bin/bash"]
