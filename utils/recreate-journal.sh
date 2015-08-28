# unmount the partition
umount /dev/xvdd1

# do an initial file system check
fsck -y /dev/xvdd1

# remove the existing journal
tune2fs -O ^has_journal /dev/xvdd1

# do a further file system check
fsck -y /dev/xvdd1

# recreate the journal
tune2fs -j /dev/xvdd1