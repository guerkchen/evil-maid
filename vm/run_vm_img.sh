 sudo qemu-system-x86_64 \
 	-drive file=ubuntu-desktop-22.04.1.img,format=raw \
	-gdb tcp::9000 \
	-smp 1 \
	-m 4G \
	--enable-kvm \
	-cpu host
