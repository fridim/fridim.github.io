# How to mount qcow2 disk image
![img](../images/cloud.png)

Use [nbd](https://github.com/NetworkBlockDevice/nbd) module and qemu-nbd.

    ::::bash
    sudo modprobe nbd max_part=8
    sudo qemu-nbd --connect=/dev/nbd0 imagename.qcow
    sudo partprobe
    mkdir -p /tmp/vm-ro
    sudo mount -o ro /dev/nbd0p2 /tmp/vm-ro
    
    #when done
    umount /tmp/vm-ro
    qemu-nbd -d /dev/nbd0
    rmmod nbd

You can safely mount RW if the image is not used by a VM, or VM is stopped. It can be a quick alternative to [virt-customize](http://libguestfs.org/virt-customize.1.html) if you need to make simple modifications on an image.

## Kernel module ?

I just came across this [paper](https://upcommons.upc.edu/bitstream/handle/2099.1/9619/65757.pdf). The guy created a kernel module, qloop to use a qcow2 image directly like a block device.

    losetup /dev/qloop0 file.qcow2

That is all. Now, the device file <code>/dev/qloop0</code> will behave like a block device containing all the data in the disk described in file.qcow2.

    losetup -d /dev/qloop0 #when done

The paper also summaries all the current methods to mount qcow2 image and even if it's from 2010, it's still worth mentioning.

- FUSE : not suitable
- libguestfs : more mature today than in 2010 (Red Hat)
- qemu-nbd : qemu official solution 
- convert to raw format : simplest, but use a lot of space

Links:

- [QLOOP Linux driver to mount QCOW2 virtual disks](https://upcommons.upc.edu/bitstream/handle/2099.1/9619/65757.pdf)
- <https://github.com/NetworkBlockDevice/nbd>
- <https://en.wikibooks.org/wiki/QEMU/Images>
- [libguestfs](http://libguestfs.org/)
- [virt-customize](http://libguestfs.org/virt-customize.1.html)
- [virt-builder](http://libguestfs.org/virt-builder.1.html)
