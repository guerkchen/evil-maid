 sudo qemu-system-x86_64 \
 	-hda debian.img \
	-gdb tcp::9000 \
	-k de \
	-smp 1
