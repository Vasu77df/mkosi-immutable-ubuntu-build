# mkosi-immutable-ubuntu-build

A readonly Ubuntu build with squashfs and an UKI

In this project we will be trying to build a Immutable Ubuntu Variant that has a readonly root filesystem, a overlay scheme with either a tmpfs overlay or presistent overlay, and finally booting using an UKI for robust trusted boot. Eventually we'll be adding an A/B image based update mechanism and others bells and whistles.

We will be using [mkosi](https://github.com/systemd/mkosi) to build our image.

## Setting up a build environment

I was short on time so while working on this so I wanted to get a build environment up and running quick.

**mkosi** and other newer systemd tools are not available in all distros yet, so we either have to use a bleeding edge distro or an unstable branch for now to start building.

The quickest way I found was to spin up a Debian Sid EC2 instance.

Here are the steps to get started.
- Head over to the EC2 console in your AWS account.
- Got to AMI Catalog and search for Debian Sid.
- You would find daily builds of AMIs, select an amd64 one as that's what we'll be using here.
- Now setup you ec2 instance, with necessary settings(make sure you setup your ssh keys)
- Launch the instance.
- Now ssh into the instance.
### Installing the build tools.

Install these packages:

```
sudo apt install systemd-boot mtools mkosi 
```

Now we should have all the build tools necessary.
## Running the build.

- Clone this project
```
sudo apt install git
git clone https://github.com/Vasu77df/mkosi-immutable-ubuntu-build.git
```

- Change into the project directory and start the build.
```
sudo mkosi -f --debug 2>&1 | tee build.log
```

- Once the build is complete you should see the built artifacts in the `build_output` dir
```
host@build_host:~/mkosi-immutable-ubuntu-build$ ls -alh build_output/
total 2.3G
drwxr-xr-x 2 admin admin 4.0K Sep 26 19:22 .
drwxr-xr-x 6 admin admin 4.0K Sep 26 19:22 ..
-rw-r--r-- 1 admin admin   15 Sep 26 19:18 .gitignore
lrwxrwxrwx 1 admin admin    9 Sep 26 19:22 image -> image.raw
lrwxrwxrwx 1 admin admin   21 Sep 26 19:21 image-initrd -> image-initrd.cpio.zst
-rw-r--r-- 1 admin admin  34M Sep 26 19:21 image-initrd.cpio.zst
-rw-r--r-- 1 admin admin  479 Sep 26 19:22 image.SHA256SUMS
-rw-r--r-- 1 admin admin 230M Sep 26 19:21 image.efi
-rw-r--r-- 1 admin admin 512M Sep 26 19:21 image.esp.raw
-rw-r--r-- 1 admin admin 217M Sep 26 19:21 image.initrd
-rw-r--r-- 1 admin admin 1.2G Sep 26 19:21 image.raw
-rw-r--r-- 1 admin admin 676M Sep 26 19:21 image.root-x86-64.raw
-rw------- 1 admin admin  14M Sep 26 19:21 image.vmlinuz
```

`image.raw` is our bootable OS disk image, we'll go over the other artifacts in a section below.
## Booting the Image. 

A quick way to test drive the build image is spinning up a `systemd-nspawn` container on the build host. You can do so with this command.

```
sudo mkosi --incremental boot
```

To exit this container press `Ctrl` + hit `]`  atleast three times.

I'll also go over instructions on how to boot the OS image on VirtualBox.
- scp down `image.raw` to your machine that has VirtualBox.
- Convert the OS disk image into an VDI, with the command
```
 VBoxManage convertdd image.raw  image.vdi --format VDI
```

- Now create virtual machine in VirtualBox and use the VDI as the hard disk for it.
- Once you have create the virtual machine make sure you enable EFI in the settings before you boot. 
- Now boot.

At this time it should just autologin into a root shell.
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
### The mkosi.cache/ dir

You would notice this is an empty dir but upon first build you will see this dir populate with the downloaded debian packages. 

If you run `sudo mkosi -f --incremental`  the tool will look at the directory to read and build the locally cached packages.

## A glance at the build artifacts.

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
- `image.efi` : this is our UKI(Unified Kernel Image) used for boot. 
	- You can see this output of this with this command 
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
- The other artifacts you see have been explained in the `[Output]` sub-section of the mkosi.conf section, hop over there to learn more about it there.
# Future work.
- Look into building a custom initrd and supplying it to the build using `Initrd`
-  With a custom initrd define an overlay scheme with persistent partition or a tmpfs.
- Make the image actually work i.e networking users etc.
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
