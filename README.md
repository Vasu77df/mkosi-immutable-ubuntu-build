# AWS Ready Immutable Ubuntu Build for Edge devices

A readonly Ubuntu variant, meant for AWS Native Cloud connected edge devices.

In this project we will be build a Immutable Ubuntu Variant that has a readonly root, setup with a tmpfs overlay through `systemd-volatile=overlay`. 

This image ships with a boot partition with a Unified Kernel image, ready for measured boot implementation, a root partition, and data partition. Eventually we'll be adding an A/B image based update scheme and others bells and whistles.

Appropriate bind mounts against certain directories like `/var/lib/docker`, and `/etc/amazon/ssm` is setup for per device unique configuration or variable data persistence. 

The disk image can be shipped and install is as simple as `dd`, to a device's disk.

We use [mkosi](https://github.com/systemd/mkosi) to build our image.

The image built includes following
- Docker and docker compose pre-installed
- SSM agent
- CloudWatch agent
- Prepped for greengrass bootstrap with a persistent bind mount unit for `/greengrass`.
- rauc for image based os updates.

## Setting up the build environment

My eventual goal is run these builds in AWS codebuild as that's what I have access to, at work. I also use Ublue's Bluefin OS for developement so installing `mkosi` direct on my laptop is not great, hence we model the build as a containerized task.

To do so we setup a build environment as a container image that will host our build. This build environement could then plugged into AWS CodeBuild that will execute the build as part CI/CD.

- Clone this project
```shell
git clone https://github.com/Vasu77df/mkosi-immutable-ubuntu-build.git
```

- Build the OS build environment container
```shell
cd mkosi-immutable-ubuntu-build
sudo docker build . -t os_build_env:latest
```

## Running the build.

Now it's just simple as running the build container and then invoking mkosi

- Run the Build container and get a shell

```shell
sudo docker run -it --privileged os_buidl_env:latest
```

- Triggering the build

```shell
/mkosivenv/bin/mkosi build
```

- Coping the artifacts
If you want to you could bind mount the `/root/build_env/build_output` dir in the container to a location on your host or you can just simply docker cp

```shell
sudo docker ps -a # get your container's name
sudo docker cp container_name:/root/build_env/build_output .
```

## Inpecting the Artifacts.

- Once the build is complete you should see the built artifacts in the `build_output` dir

```
⋊> ~/w/mkosi-immutable-ubuntu-build on main ⨯ ls -alh build_output                                                                                                 17:58:50
total 33G
drwxr-xr-x 1 root    root     348 Dec  8 17:19 ./
drwxr-xr-x 1 vasuper vasuper  134 Dec  8 17:58 ../
drwxr-xr-x 1 root    root     202 Dec  8 17:15 base/
drwxr-xr-x 1 root    root     302 Dec  8 17:16 core/
-rw-r--r-- 1 root    root      15 Nov 28 18:47 .gitignore
lrwxrwxrwx 1 root    root       9 Dec  8 17:19 image -> image.raw
-rw-r--r-- 1 root    root    447M Dec  8 17:19 image.efi
-rw-r--r-- 1 root    root    2.0G Dec  8 17:19 image.esp.raw
-rw-r--r-- 1 root    root    432M Dec  8 17:19 image.initrd
-rw-r--r-- 1 root    root     10G Dec  8 17:19 image.linux-generic.raw
-rw-r--r-- 1 root    root    2.1K Dec  8 17:19 image.manifest
-rw-r--r-- 1 root    root     16G Dec  8 17:19 image.raw
-rw-r--r-- 1 root    root    3.8G Dec  8 17:19 image.root-x86-64.raw
-rw-r--r-- 1 root    root     569 Dec  8 17:19 image.SHA256SUMS
-rw-r--r-- 1 root    root     15M Dec  8 17:19 image.vmlinuz
lrwxrwxrwx 1 root    root      15 Dec  8 17:16 initrd -> initrd.cpio.zst
-rw-r--r-- 1 root    root     43M Dec  8 17:16 initrd.cpio.zst
```

- `image` or to be exact `image.raw` is our bootable artifact, you can inspect it with `systemd-dissect`


```
sudo systemd-dissect --no-pager image.raw
```

**Output**:
```
      Name: image.raw
      Size: 15.7G
 Sec. Size: 512
     Arch.: x86-64

Image UUID: 3644712f-284e-4a62-9dc4-6422968e1ab0
  Hostname: immutable-noble
Machine ID: 5ba2430ae4ad4d17b28eef6f6ad47935
OS Release: PRETTY_NAME=Ubuntu 24.04.1 LTS
            NAME=Ubuntu
            VERSION_ID=24.04
            VERSION=24.04.1 LTS (Noble Numbat)
            VERSION_CODENAME=noble
            ID=ubuntu
            ID_LIKE=debian
            HOME_URL=https://www.ubuntu.com/
            SUPPORT_URL=https://help.ubuntu.com/
            BUG_REPORT_URL=https://bugs.launchpad.net/ubuntu/
            PRIVACY_POLICY_URL=https://www.ubuntu.com/legal/terms-and-policies/privacy-policy
            UBUNTU_CODENAME=noble
            LOGO=ubuntu-logo

    Use As: ✓ bootable system for UEFI
            ✓ bootable system for container
            ✗ portable service
            ✗ initrd
            ✗ sysext for system
            ✗ sysext for portable service
            ✗ sysext for initrd
            ✗ confext for system
            ✗ confext for portable service
            ✗ confext for initrd

RW DESIGNATOR PARTITION UUID                       PARTITION LABEL FSTYPE ARCHITECTURE VERITY GROWFS NODE         PARTNO
rw root       e016523a-ac25-43d0-acc0-bb25606e8ae5 root-x86-64     ext4   x86-64       no     yes    /dev/loop0p2      2
rw esp        b179c7c5-5c48-4fe9-aa56-06c6b368209b esp             vfat   -            -      no     /dev/loop0p1      1

```

- `fdisk` output to see all partitions

```
sudo fdisk -l image.raw
```

**Output**:
```
Disk image.raw: 15.75 GiB, 16911544320 bytes, 33030360 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3644712F-284E-4A62-9DC4-6422968E1AB0

Device        Start      End  Sectors  Size Type
image.raw1     2048  4196351  4194304    2G EFI System
image.raw2  4196352 12058799  7862448  3.7G Linux root (x86-64)
image.raw3 12058800 33030319 20971520   10G Linux filesystem
```


## Booting the image.

`mkosi` itself has various boot options like `qemu` for hardware virtualization and `systemd-nspawn` containers, you can invoke them on your own as well for exampel for `systemd-nspawn`

```
sudo systemd-nspawn -bi image.raw
```

*Note: nspawn is container virtualization so some mount units are bound to fail as it does not setup the data partition.*

## Explaining what is going in here.

[mkosi](https://github.com/systemd/mkosi) is a declarative bespoke OS Image build tool. 

This tools follow the systemd unit file convention for declaring settings for a build.
### mkosi.conf

When running a mkosi build from a directory it reads config in `mkosi.conf` or the configs i ``./mkosi.conf.d/`` for a build. 

At the moment we just have mkosi.conf and we'll be expanding as the project progresses.

I will only explain the options that's used at the moment, check the manpage for mkosi for all the available options of mkosi if you are interested:
- https://manpages.debian.org/unstable/mkosi/mkosi.1.en.html

First we declare the Distribution and architecture here. Note that I haven't declared the Version, by default it would take the latest Version i.e Lunar Lobster. This is the behavior I want because Jammy does not support systemd-boot out-of-the box, and I will not be bothering with setting up mirrors to get that working in Jammy for now.

Next is the `[OUTPUT]` section. Here we declare:
- `Format` with is set to disk, which produces a GPT partitioned disk image, which is what I need. 
	- mkosi uses [systemd-repart](https://www.freedesktop.org/software/systemd/man/systemd-repart.service.html) , a declarative tool to add and grow partitions to a partition table.
- `OutputDirectory=./build_output`  defines the output directory
- `SplitArtifacts=yes` : This options is set to obtain separate artifact for each partition produces by the built disk image. From the output we saw early above this would be `image.esp.raw` which is disk image of the boot partition and `image.root-x86-64.raw` is a disk image of root filesystem. We will be using these and the UKI as update artifacts for A/B update mechanism down the line.

The `[Content]`  section;

- `Packages`: pretty obvious, its all the packages apart from the base that you want installed
- `Bootable=yes`: setting this is what creates a ESP partition and also installs/creates(?) the efi stub for boot like systemd-bootx64.efi. more info on this can be found in the manpage.
- `Bootloader=systemd-boot`: This option lets you define the bootloader you want. Here we want systemd-boot as it's easiest to interface with UKIs, but you could set Grub or straight build a UKI with the rootfs in the initrd with the uki option.
- `AutoLogin=yes`, first run, not setting up users, just going to autologin to root.

The `Validation` section:
- `Checksum=yes` : creates a checksum file for all the created artifacts  from a build
```
host@host:~/mkosi-immutable-ubuntu-build/build_output$ cat image.SHA256SUMS 
17054d2e860f14b158e39c7d9547501a1a48e1e157ec55b664ea6cf4883a8330 *image.efi
408b6860ae32802a8f2d6f561b24786b8bebdd5121478978ad30322f1babeb38 *image.root-x86-64.raw
fbd50011d3627e84ed6d4c20f5bd58d0b9b5c9413f35f363d8329f3bbe744e7e *image.raw
f65bf608d56f085c4b0d32c65bc79434830996a9347e8b80844d2fa3023704be *image.initrd
ce440af9ea65e7deb13c6164efd5556b1ec0bf60e172ef54ba23716b57980403 *image.esp.raw
02fa6909a538cc6bccaad2f7dad49caa74be8488a62cc77b2c010e1687a76016 *image.vmlinuz
```

- This section is sparse for now, but this is where we would declare Verity, Measured Boot and SecureBoot options
### The mkosi.repart/ dir

The `mkosi.repart/` dir is where we declare all our partition options for the the disk image we build. Essentially as the mkosi uses [systemd-repart](https://www.freedesktop.org/software/systemd/man/systemd-repart.service.html) to set partitions and build disk images, this is where configs for `repart.d` exist. 

No more imperative setup of partitions, all partitions schemes could be declared through `mkosi.repart/` 

Partition declaration and filesystem type in `repart.d` take the same convention of systemd unit files. 

In this project, you will see `00-esp.conf` here, this is what declares the ESP/EFI partition and it's options like format and size, etc.

You will also see `10-root.conf` , this is where we declare the root partition. Notice that we set the format to squashfs, this is the first step to a readonly rootfs, we also add options like `CopyFiles=/` that takes a pair of colon separated absolute file system paths. here it's just the root `/` as we consider the entire root readonly for now.

More info on all the options can be found in the manpages here:
- https://www.freedesktop.org/software/systemd/man/repart.d.html#

## Another glance at the build artifacts.

These are all the build artifacts

```
host@host:~/mkosi-immutable-ubuntu-build$ ls -lah build_output/
total 2.3G
drwxr-xr-x 2 admin admin 4.0K Sep 26 19:29 .
drwxr-xr-x 6 admin admin 4.0K Sep 26 19:22 ..
-rw-r--r-- 1 admin admin   15 Sep 26 19:18 .gitignore
lrwxrwxrwx 1 admin admin    9 Sep 26 19:22 image -> image.raw
lrwxrwxrwx 1 admin admin   21 Sep 26 19:21 image-initrd -> image-initrd.cpio.zst
-rw-r--r-- 1 admin admin  34M Sep 26 19:21 image-initrd.cpio.zst
-rw-r--r-- 1 admin admin  479 Sep 26 19:22 image.SHA256SUMS
-rw-r--r-- 1 admin admin 230M Sep 26 19:21 image.efi
-rw-r--r-- 1 admin admin 512M Sep 26 19:21 image.esp.raw
-rw-r--r-- 1 admin admin 217M Sep 26 19:21 image.initrd
-rw-r--r-- 1 admin admin 8.0G Sep 26 19:29 image.raw
-rw-r--r-- 1 admin admin 676M Sep 26 19:21 image.root-x86-64.raw
-rw------- 1 admin admin  14M Sep 26 19:21 image.vmlinuz
```

- `image-initrd.cpio.zst` is the compressed built initrd
- `image.SHA256SUM` is the Checksum file, look at the sections above for the output of this file
- `image.manifest` is the SBOM of the image build
- `image.efi` : this is our UKI(Unified Kernel Image) used for boot. 

You can see the sections of the UKI with `objdump`
```
objdump -h image.efi 

image.efi:     file format pei-x86-64

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         0000c0f0  0000000000004000  0000000000004000  00000400  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .reloc        0000000c  0000000000011000  0000000000011000  0000c600  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .data         000033d8  0000000000012000  0000000000012000  0000c800  2**4
                  CONTENTS, ALLOC, LOAD, DATA
  3 .dynamic      00000110  0000000000016000  0000000000016000  0000fc00  2**2
                  CONTENTS, ALLOC, LOAD, DATA
  4 .rela         00000f30  0000000000017000  0000000000017000  0000fe00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  5 .dynsym       00000018  0000000000018000  0000000000018000  00010e00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  6 .sbat         000000e2  000000000001a000  000000000001a000  00011000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  7 .sdmagic      00000034  000000000001a100  000000000001a100  00011200  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  8 .osrel        00000185  000000000001a200  000000000001a200  00011400  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  9 .cmdline      0000000e  000000000001a400  000000000001a400  00011600  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 10 .uname        00000010  000000000001a600  000000000001a600  00011800  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 11 .initrd       0d8aa1e8  000000000001a800  000000000001a800  00011a00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 12 .linux        00d31a68  000000000d8c4a00  000000000d8c4a00  0d8bbc00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
```

- If you loop mount the EFI partition of image.raw you can find the same under ``EFI/Linux``:
```
❯ objdump -h EFI/Linux/ubuntu-6.2.0-33-generic.efi

EFI/Linux/ubuntu-6.2.0-33-generic.efi:     file format pei-x86-64

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         0000c0f0  0000000000004000  0000000000004000  00000400  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .reloc        0000000c  0000000000011000  0000000000011000  0000c600  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .data         000033d8  0000000000012000  0000000000012000  0000c800  2**4
                  CONTENTS, ALLOC, LOAD, DATA
  3 .dynamic      00000110  0000000000016000  0000000000016000  0000fc00  2**2
                  CONTENTS, ALLOC, LOAD, DATA
  4 .rela         00000f30  0000000000017000  0000000000017000  0000fe00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  5 .dynsym       00000018  0000000000018000  0000000000018000  00010e00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  6 .sbat         000000e2  000000000001a000  000000000001a000  00011000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  7 .sdmagic      00000034  000000000001a100  000000000001a100  00011200  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  8 .osrel        00000185  000000000001a200  000000000001a200  00011400  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  9 .cmdline      0000000e  000000000001a400  000000000001a400  00011600  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 10 .uname        00000010  000000000001a600  000000000001a600  00011800  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 11 .initrd       0d8aa1e8  000000000001a800  000000000001a800  00011a00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
 12 .linux        00d31a68  000000000d8c4a00  000000000d8c4a00  0d8bbc00  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
```

- `image.initrd` is the uncompressed initrd

# Future work.
- Look into building a custom initrd and supplying it to the build using `Initrd`
- With a custom initrd define an overlay scheme with persistent partition or a tmpfs.
- Add options of disk encryption and verity,
- Add options for measured boot.
# Some really good references;
- https://github.com/systemd/mkosi
- https://github.com/systemd/systemd/tree/main/mkosi.presets
- https://github.com/edgelesssys/constellation/tree/main/image
- https://manpages.debian.org/unstable/mkosi/mkosi.1.en.html
- https://www.freedesktop.org/software/systemd/man/repart.d.html#
- https://0pointer.net/blog/mkosi-a-tool-for-generating-os-images.html
- https://www.youtube.com/watch?v=6EelcbjbUa8
