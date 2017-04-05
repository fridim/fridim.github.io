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

You can safely mount RW if the VM is stopped.

Links:

- <https://github.com/NetworkBlockDevice/nbd>
- <https://en.wikibooks.org/wiki/QEMU/Images>

