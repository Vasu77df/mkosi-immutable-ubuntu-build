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
sudo mkosi -f
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




