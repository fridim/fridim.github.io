Create an OpenBSD live USB stick
--------------------------------
<small>2014-06-25 by fridim ~ #openbsd #gpg #kvm #qemu</small>

The beginning of the article
[offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard](http://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/)
deals with the creation of a master GPG key on an **offline** computer. The
author uses a Debian Live CD for that task.

I thought : Why not boot a tiny OpenBSD instead ?

I [looked](http://ftp.fr.openbsd.org/pub/OpenBSD/5.5/amd64/) for one on the
official website: there is only the installation image.  I found
[livecd-openbsd](http://livecd-openbsd.sourceforge.net/) and
[liveusb-openbsd](http://liveusb-openbsd.sourceforge.net/), but I don't trust
them. So here is a way to create one puffy USB stick.

Dependency : <code>qemu</code>

    :::bash
    wget http://ftp.fr.openbsd.org/pub/OpenBSD/5.5/amd64/install55.iso
    sha256sum install55.iso # should be cc465ce3f8397883e91c6e1a8a98b1b3507a338984bbfe8978050c5f8fdcaf3f
    qemu-img create liveusb.img 825000k # you may need more space if you want X
    qemu-system-x86_64 -hda liveusb.img -m 1024 -cdrom install55.iso # perform install

Once installation is done, you may want to add additional packages. Inside the VM:

    :::bash
    reboot
    export PKG_PATH=http://ftp.fr.openbsd.org/pub/OpenBSD/5.5/packages/amd64/
    pkg_add gnupg # for example
    shutdown -h now

From the Linux again:

    :::bash
    dd if=liveusb.img of=/dev/sdc bs=512k ; sync # replace /dev/sdc with your usb stick device
    qemu-system-x86_64 -usb -hda /dev/sdc  # test to see if it boot

It's ready!
