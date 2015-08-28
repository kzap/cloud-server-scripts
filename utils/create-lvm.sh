# From a Rackspace Dev, haven't tried it yet, beware

echo RTFM >&2;
exit -1;

N=1
yum install -y lvm2
D=$(grep "unknown partition table" /var/log/messages | tail -n 1 | perl -pe 's/.*: ([^:]*): unknown.*/$1/g');
D=/dev/$D
pvcreate $D
vgcreate vg_$N $D
S=$(vgdisplay vg_$N | grep Total | perl -pe 's/[^0-9]+//g')
lvcreate -l $S vg_$N -n lv_$N
mke2fs -t ext4 /dev/vg_"$N"/lv_$N
tune2fs -m 0 /dev/vg_"$N"/lv_$N
mkdir /media/Volume-$N
mount /dev/vg_"$N"/lv_$N /media/Volume-$N
echo -e "/dev/vg_"$N"/lv_"$N"\t\t/media/Volume-"$N"\t\text4\tnoatime\t\t0 2" >> /etc/fstab