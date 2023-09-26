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

Now ssh into the instance.

### Installing the build tools.

Install these packages:

```
sudo apt install systemd-boot mtools mkosi
```
