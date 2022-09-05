# evil-maid
In this project I want to launch an [evil maid attack](https://en.wikipedia.org/wiki/Evil_maid_attack) on an ubuntu laptop for fun.
This is no new approach and there are many defensive measures, but I want to try it anyway.

# Let's get started #
Goal of this project is to attack an ubuntu system, where full disk encryption (FDE) is activated.
When FDE is activated, without the keyphrase it is practically impossible to access the encrypted data.
Therefore we must persuade the victim to tell us the password.
Since some victims are not willing enough to do that (and torture is not a nice way to change that), we try another approach by tricking the victim to give us the password.  
![a man being tortured](/img/torture.jpg)

The computer cannot encrypt the whole hard drive, since then it would be unable to ask the user for the keyphrase.
Because of this a small portion with the boot partition is unencrypted.
When the computer is booting, the user is asked to enter the keyphrase required to continue the boot process.
In this project, we try to manipulate the part of the code handling the keyphrase, so a file is created on the hard drive, containing the entered keyphrase.  

![super mario shouting Let's a go](/img/letsago.jpg)

# Setup #  
For the final target, probably my ubuntu laptop with FDE will be used.
Since I do not want to lower the security of my laptop significally, I really should not only focus on implementing the attack, but also to remove it afterwards.
For developing I rather prefer working with a VM, since it is much easier to debug and I can just reset the status when I screw up.

This creates a small problem: I only have a linux laptop with a small screen (15"), but I would rather enjoy working on my two big 24" screens with all the nice equipment.
The computer mounted to the big screens is running on Windows 11. Of course I can create a linux VM and start developing inside of it, but for testing I need a nested VM inside the linux VM and this stinks.  
![drake does not like the movie inception](/img/inception.jpg)  

But luckily, newer Windows versions feature the brilliant Windows-Subsystem for Linux (WSL). 
Eventhough I did not except it to work, for the moment I can start a qemu VM with ubuntu and attach GDB as a debugger. 
Wohooo!  


So with this achivement, the development is completely done on my Windows machine, using WSL, qemu and GDB.
Since I can reuse code parts of my master thesis, the controller is written in GOlang. As far as possible I will try to avoid writing bare ASM, but C. For compiling I will use gcc and go.

```console
matze@Matze-PC:~/evil-maid/vm$ uname -a
Linux Matze-PC 5.10.16.3-microsoft-standard-WSL2 #1 SMP Fri Apr 2 22:23:49 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
matze@Matze-PC:~/evil-maid/vm$ gdb --version
GNU gdb (Ubuntu 9.1-0ubuntu1) 9.1
```

## Setting up the VM ##
For testing purposes an ubuntu VM is setup in qemu.
I use qemu because I know it from my master thesis, it is lightweight and it runs on WSL.
Just for protocoll, this is the used qemu version: QEMU emulator version 4.2.0 (Debian 1:4.2-3ubuntu6)  
I setup the VM using a simple web [tutorial](https://graspingtech.com/ubuntu-desktop-18.04-virtual-machine-macos-qemu/), but instead of 18.04, I use [Ubuntu 22.04.1 LTS (Jammy Jellyfish)](https://releases.ubuntu.com/22.04/) since it is the newest version currently available. I hope this doesn't backfire :wink:. Like in the tutorial I use 10GB of space, I hope this is enough.  
I don't want to heavily increase the size of this repo by commiting the VM, so it is excluded and can be downloaded [here](https://here-the-author-must-include-a-link.com).

I highly recommend to take your time and get the launch paramters for qemu right. Otherwise it might be possible, you find yourself spending a few hours trying to fix non existing problems. Oh and you really should use KVM! I think here is the right moment to highlight the benefits of a VM with KVM. Only an idiot would try to install Ubuntu on a VM without KVM.  
![sloth VM](/img/sloth.jpg)  
Anyway, I choose the german keyboard design, since I am from Germany :beer:, and the minimal installation, no updates during setup and of course no optional third party software. The VM should be as thin as possible.  
When choosing the installation type, I choose LVM and "Encrypt the new Ubuntu installation for security" (since this is the whole purpose of this project).  
Since the keyphrase is about to get leaked anyway, I can write it here. The keyphrase is *evil-maid-2022*.  
I choose not to use a recovery key, I think I can remeber the password, since it is documented in the Readme.

## Getting access to the qcow2-Iamge content ##
For attacking the unencrypted boot-section of the Image, it is really helpful to be able to mount the partitions of the qcow2 file.
To my misfortune, this is easier said then done. Mounting a qcow2 Image on WSL is sadly not possible by using [nbd](https://gist.github.com/shamil/62935d9b456a6f9877b5).  
After some research I found a promising [Stack-Overflow Thread](https://stackoverflow.com/questions/53874221/mount-disk-image-on-wsl-windows-subsystem-for-linux), where mounting an ISO image is described.
Converting qcow2 to an iso is quite a challenge, I found [this manual](https://docs.openstack.org/image-guide/convert-images.html), where converting a qcow2 image to an raw image and [this page](https://www.maketecheasier.com/convert-img-to-iso-linux/), where multiple ways to convert a raw image to an iso file are described. Using ccd2iso did not work on my machine, but iat is running since 4 hours and it might finish in a few days ...

I must be able to analyze the content of the image, to continue. Of course, I can export the required files out of while the qemu machine is running, but I want to have a look at the encrypted image right now. So I did the only logic thing and setup a VM in VMWare, where I share the vm folder and mount the qcow2 there. There are probably far better solutions, but now I am able to mount the qcow image using [this tutorial](https://unix.stackexchange.com/a/598265) and edit it from inside my VMWare Linux VM.

# Research # 

## Analyze the unencrypted root partition ##

```console
matze@matze-virtual-machine:/media/matze/79c7119f-3fb9-4133-958a-baccc110e8f6$ ls -la
total 251408
drwxr-xr-x  5 root root      4096 Aug 30 18:35 .
drwxr-x---+ 3 root root      4096 Sep  2 18:39 ..
-rw-r--r--  1 root root    261694 Jul 12 10:51 config-5.15.0-43-generic
-rw-r--r--  1 root root    261879 Aug  4 19:16 config-5.15.0-46-generic
drwxrwxr-x  2 root root      4096 Aug 30 18:25 efi
drwxr-xr-x  6 root root      4096 Aug 31 16:59 grub
lrwxrwxrwx  1 root root        28 Aug 30 18:35 initrd.img -> initrd.img-5.15.0-46-generic
-rw-r--r--  1 root root 109929157 Aug 30 18:35 initrd.img-5.15.0-43-generic
-rw-r--r--  1 root root 111253499 Aug 30 18:35 initrd.img-5.15.0-46-generic
lrwxrwxrwx  1 root root        28 Aug 30 18:25 initrd.img.old -> initrd.img-5.15.0-43-generic
drwx------  2 root root     16384 Aug 30 18:24 lost+found
-rw-r--r--  1 root root    182800 Feb  6  2022 memtest86+.bin
-rw-r--r--  1 root root    184476 Feb  6  2022 memtest86+.elf
-rw-r--r--  1 root root    184980 Feb  6  2022 memtest86+_multiboot.bin
-rw-------  1 root root   6250707 Jul 12 10:51 System.map-5.15.0-43-generic
-rw-------  1 root root   6252303 Aug  4 19:16 System.map-5.15.0-46-generic
lrwxrwxrwx  1 root root        25 Aug 30 18:35 vmlinuz -> vmlinuz-5.15.0-46-generic
-rw-r--r--  1 root root  11090688 Aug  9 14:00 vmlinuz-5.15.0-43-generic
-rw-------  1 root root  11531520 Aug  4 19:34 vmlinuz-5.15.0-46-generic
lrwxrwxrwx  1 root root        25 Aug 30 18:35 vmlinuz.old -> vmlinuz-5.15.0-43-generic
```

Eventough I tried my best not to install any updates, somehow there are an old image anyway (5.13.0-43-genric). But we are only taking a look at newest and currently installed kernel 5.15.0-46-generic.
The important parts of the folder are described on [this website](https://wiki.debian.org/FilesystemHierarchyStandard/Directory/boot).  
- *config-5.15.0-46-generic* contains boring configuration options the kernel binary was compiled with.  
- *System.map-5.15.0-46-generic* contains symbol names and addresses of the linux kernel binary. It is probably helpful to reverse enginner the functions responsible for handling the keyphrase.  
- *initrd.img-5.15.0-46-generic* is a small, temporary, root filesystem used solely for boot strapping your system. This could be the binary responsible for handling the keyphrase. If that is the case, we probably cannot use the System.map for reverse engineering, since it not contains the function addresses of the initrd. Futhermore we have to take a deep dive into the limited functionality available during the startup process.  
- *vmlinuz-5.15.0-46-generic* is the compiled kernel binary. I hope the keyphrase handling is done in here, since then we would be able to execute system calls and some other nice stuff.
