#!/bin/bash/

# created from modified instructions provided by
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-simple-install-kickstart#bridgehead.gen-usb-media

#add the centos-7.iso and anaconda-ks.cfg to the /tmp

#mount the installation ISO file to mnt directory
mount -o loop /tmp/<replace with iso file> /mnt/

#create working directory and copy dvd content to it
mkdir /root/centos-install/
shopt -s dotglob
cp -avRf /mnt/* /root/centos-install/

#unmount iso file
umount /mnt/

#copy ks to working directory
cp /tmp/<kickstartfilename-ks.cfg> /root/centos-install/

#Display the installation DVD volume name (not necessary for centos so much)
isoinfo -d -i <iso file name> | grep "Volume id"
# (in progress not reall needed)
# sed -e 's/Volume id: //' -e 's/ /\\x20/g' \
# CENTOS\207\x20x86_64

#add new menu entry to boot menu
/root/centos-install/isolinux/isolinux.cfg

#build the dvd iso 
mkisofs -J -T -o /root/<name of your iso.iso> -b isolinux/isolinux.bin \
-c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
-R -m TRANS.TBL -graft-points -V "CENTOS 7 x86_64" \
/root/centos-install/