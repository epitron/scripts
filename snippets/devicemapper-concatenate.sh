# How to combine multiple files into one contiguous file with devicemapper

# for testing, Create 4 files
echo foo | dd of=block0 cbs=512 conv=block
echo bar | dd of=block1 cbs=512 conv=block
echo bat | dd of=block2 cbs=512 conv=block
echo baz | dd of=block3 cbs=512 conv=block

# Create a loop device for each of the 4 files
losetup /dev/loop0 block0
losetup /dev/loop1 block1
losetup /dev/loop2 block2
losetup /dev/loop3 block3

# Create a device map named "test" using those loop devices
(
    echo "0 1 linear /dev/loop0 0"
    echo "1 1 linear /dev/loop1 0"
    echo "2 1 linear /dev/loop2 0"
    echo "3 1 linear /dev/loop3 0"
) | dmsetup create test

cat /dev/mapper/test
