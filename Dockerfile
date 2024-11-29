FROM public.ecr.aws/ubuntu/ubuntu:24.04_stable
LABEL maintainer="@vasuper"

ARG DEBIAN_FRONTEND=noninteractive

# All build tools
# aptly                 :To build debian repos and packages
# build-essentials      :complilers like gcc and gnu debuggerm when we start compiling systemd and the kernel from source
# bubblewrap            :sandboxing, and permissions for unprivileged execution used by mkosi
# ca-certificates       :common ca certs for signed mirrors
# cpio                  :for creating cpio archives, used to create initrd and disk images
# curl                  :to make calls over the network
# dofstools             :installs commands like mkfs.fat, required to creat a boot partition
# e2fsprogs             :ext fs tools,  to create the rootfs
# git                   :pip install mkosi from a git repo
# kmod                  :program to manage linux kernel modules
# procps                :utilities for /proc
# python3-cryptography  :crypto library for python
# python3-pip
# python3-venv
# python3-setuptools    :python deps to get a python project installed
# python3-wheel
# rauc                  :used to build the OS bundle
# sbsigntool            :tool for secure boot signing, and general signing
# squashfs-tools        :used to create squashfs rootfs if requested
# systemd               :systemd utilities
# systemd-boot          :utilities to setup systemd bootloader
# systemd-container     :tools to manipulate disk images for layering
# systemd-ukify         :utility to build an unfied kernel image
# tpm2-tools             :general tpm tools
# mtools                :various gpt disk utilities
# ubuntu-keyring        :gpg keyring to access ubuntu mirrors
# unzip                 :extract files
# zstd                  :compression library used in building initrd

# Install Everything
RUN apt update -y && apt upgrade -y && apt install -y \
    aptly \
    bubblewrap \
    ca-certificates \
    cpio \
    curl \
    debian-archive-keyring \
    dosfstools \
    e2fsprogs  \
    git \
    kmod \
    procps \
    python3-cryptography \
    python3-pip \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    rauc \
    sbsigntool \
    squashfs-tools \
    systemd \
    systemd-boot \
    systemd-repart \
    systemd-ukify \
    systemd-container \
    mtools \
    tpm2-tools \
    ubuntu-keyring \
    unzip \
    zstd

RUN apt install -y libc6 groff less \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && ls -alh \
    && unzip ./awscliv2.zip \
    && ./aws/install

# Install amazon-ssm-agent to allow access in CodeBuild
RUN curl -o /tmp/amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb \
    && dpkg -i /tmp/amazon-ssm-agent.deb \
    && curl -o /etc/amazon/ssm/amazon-ssm-agent.json https://raw.githubusercontent.com/aws/aws-codebuild-docker-images/master/ubuntu/standard/5.0/amazon-ssm-agent.json


# cleanup
RUN rm --force --recursive /var/lib/apt/lists/* \
    && rm --force --recursive /usr/share/doc \
    && rm --force --recursive /usr/share/man \
    && apt clean

# Allow installing stuff to system Python.
RUN rm --force /usr/lib/python3.12/EXTERNALLY-MANAGED && \
    apt-get update && \
    apt-get install -y python3-pip && \
    pip install pefile

RUN python3 -m venv mkosivenv \
    && mkosivenv/bin/pip install git+https://github.com/systemd/mkosi.git@v24.3 \
    && mkosivenv/bin/mkosi --version

# Make the logging more real time
ENV PYTHONUNBUFFERED=TRUE

# Since each execution starts from a clean image
#   there is no need to create python bytecode
ENV PYTHONDONTWRITEBYTECODE=TRUE

WORKDIR /root/build_env

COPY definitions/ /root/build_env
