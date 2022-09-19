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

I made a noval approach working with WSL, but I surrendered when mounting the qcow2 image, since this is not an easy task on an Windows machine using WSL. So, fortunetly a few days ago I switched the M.2 SSD in one of my laptops to a bigger one, so I got an unused 128 GB M.2 SSD on my hands. I installed it in my desktop computer and setup dual boot, so now I am working on a workhorse with linux.
Wohoooo.

Since I can reuse code parts of my master thesis, the controller is written in GOlang. As far as possible I will try to avoid writing bare ASM, but C. For compiling I will use gcc and go.

```console
matze@Matze-PC:~/evil-maid/vm$ uname -a
Linux matze-linux 5.15.0-47-generic #51-Ubuntu SMP Thu Aug 11 07:51:15 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
matze@Matze-PC:~/evil-maid/vm$ gdb --version
GNU gdb (Ubuntu 12.0.90-0ubuntu1) 12.0.90
```

## Setting up the VM ##
For testing purposes an ubuntu VM is setup in qemu.
I use qemu because I know it from my master thesis, it is lightweight and it runs on WSL (eventhough I don't need that future anymore, since I work on an ubuntu machine).
Just for protocoll, this is the used qemu version: QEMU emulator version 6.2.0 (Debian 1:6.2+dfsg-2ubuntu6.3)  
I setup the VM using a simple web [tutorial](https://graspingtech.com/ubuntu-desktop-18.04-virtual-machine-macos-qemu/), but instead of 18.04, I use [Ubuntu 22.04.1 LTS (Jammy Jellyfish)](https://releases.ubuntu.com/22.04/) since it is the newest version currently available. I hope this doesn't backfire :wink:. Like in the tutorial I use 10GB of space, I hope this is enough.  
I don't want to heavily increase the size of this repo by commiting the VM, so it is excluded and can be downloaded [here](https://here-the-author-must-include-a-link.com).

I highly recommend to take your time and get the launch paramters for qemu right. Otherwise it might be possible, you find yourself spending a few hours trying to fix non existing problems. Oh and you really should use KVM! I think here is the right moment to highlight the benefits of a VM with KVM. Only an idiot would try to install Ubuntu on a VM without KVM.  
![sloth VM](/img/sloth.jpg)  
Anyway, I choose the german keyboard design, since I am from Germany :beer:, and the minimal installation, no updates during setup and of course no optional third party software. The VM should be as thin as possible.  
When choosing the installation type, I choose LVM and "Encrypt the new Ubuntu installation for security" (since this is the whole purpose of this project).  
Since the keyphrase is about to get leaked anyway, I can write it here. The keyphrase is *evil-maid-2022*.  
I choose not to use a recovery key, I think I can remeber the password, since it is documented in the Readme.

```console
matze@matze-Standard-PC-i440FX-PIIX-1996:~$ uname -a  
Linux matze-Standard-PC-i440FX-PIIX-1996 5.15.0-46-generic #49-Ubuntu SMP Thu Aug 4 19.03.25 UTC 2022 x86_64 x86_64 GNU/Linux  
```

## Getting access to the qcow2-Iamge content ##
For attacking the unencrypted boot-section of the Image, it is really helpful to be able to mount the partitions of the qcow2 file.
Mounting the qcow2 image on ubuntu is pretty easy, using [this tutorial](https://gist.github.com/shamil/62935d9b456a6f9877b5).
There is just a small catch: I cannot start the VM while the image is mounted due to the requirement of write access.
So I wrote to simple scripts, one for mounting the boot partition and one for unmounting the partition and now I am fine.
Man, this is so much easier then over WSL.

# Research # 

## Analyze the unencrypted root partition ##

```console
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

## Find the entry point ##

There are several imaginable ways to find the code section, where the keyphrase is handeled and it is hard to predict the easiest one.  
### First try: Break during password input window is shown ###
So I decided to try it by booting up the VM and waiting for the keyphrase enter screen to appear. Then I attach GDB which pauses the VM and prints out the current position of the RIP (Instruction pointer). For this to work flawless, [*kaslr* must be disabled in grub on the guest machine](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hibernation-disable-kaslr.html). The address of the RIP in the VM is 0xffffffff81daa6bb :sunglasses:.  
So I stop the VM, mount the boot drive and use the System.map to map the address to the corresponding method. The address is located in the function native_safe_halt :disappointed:. I don't even need to investigate this function any futher. That is the idle loop, cpu cores chilling in, when they have nothing else to do. Looking back, it is no big suprise, since the cpu core really does not have any job  except waiting for the user input. But it is actually not that big of a deal, since we can investigate, where the native_safe_halt function is called from, by using the backtrace command.
For the backtrace command it is very useful to import the symbol table into gdb, so not only the return adresses are shown, but the function names aswell. I found [this tutorial](https://www.ibm.com/docs/en/linux-on-systems?topic=linuxonibm/liacf/oprofkernelsymrhel.html).

```console
(gdb) target remote localhost:9000
Remote debugging using localhost:9000
Warnung: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.
0xffffffff81daa6bb in ?? ()
(gdb) symbol-file /usr/lib/debug/boot/vmlinux-5.15.0-46-generic 
Reading symbols from /usr/lib/debug/boot/vmlinux-5.15.0-46-generic...
(gdb) bt
#0  0xffffffff81daa6bb in native_safe_halt ()
    at /build/linux-22xc9F/linux-5.15.0/arch/x86/include/asm/irqflags.h:52
#1  0xffffffff81daa5be in arch_safe_halt ()
    at /build/linux-22xc9F/linux-5.15.0/arch/x86/include/asm/paravirt.h:167
#2  default_idle () at /build/linux-22xc9F/linux-5.15.0/arch/x86/kernel/process.c:732
#3  0xffffffff8104b922 in arch_cpu_idle ()
    at /build/linux-22xc9F/linux-5.15.0/arch/x86/kernel/process.c:724
#4  0xffffffff81daa7de in default_idle_call ()
    at /build/linux-22xc9F/linux-5.15.0/kernel/sched/idle.c:112
#5  0xffffffff81108719 in cpuidle_idle_call ()
    at /build/linux-22xc9F/linux-5.15.0/kernel/sched/idle.c:194
#6  0xffffffff81108803 in do_idle () at /build/linux-22xc9F/linux-5.15.0/kernel/sched/idle.c:306
#7  0xffffffff81108a30 in cpu_startup_entry (state=state@entry=CPUHP_ONLINE)
    at /build/linux-22xc9F/linux-5.15.0/kernel/sched/idle.c:403
#8  0xffffffff81d9c8d3 in rest_init () at /build/linux-22xc9F/linux-5.15.0/init/main.c:735
#9  0xffffffff83298781 in arch_call_rest_init () at /build/linux-22xc9F/linux-5.15.0/init/main.c:888
#10 0xffffffff83298c7e in start_kernel () at /build/linux-22xc9F/linux-5.15.0/init/main.c:1146
#11 0xffffffff8329762d in x86_64_start_reservations (
    real_mode_data=real_mode_data@entry=0x8b000 <error: Cannot access memory at address 0x8b000>)
    at /build/linux-22xc9F/linux-5.15.0/arch/x86/kernel/head64.c:525
#12 0xffffffff83297717 in x86_64_start_kernel (
    real_mode_data=0x8b000 <error: Cannot access memory at address 0x8b000>)
    at /build/linux-22xc9F/linux-5.15.0/arch/x86/kernel/head64.c:506
#13 0xffffffff81000107 in secondary_startup_64 ()
    at /build/linux-22xc9F/linux-5.15.0/arch/x86/kernel/head_64.S:283
#14 0x0000000000000000 in ?? ()
```

This backtrace shows us a sleeping cpu, which is kind of obvious, since the kernel is waiting for an interrupt aka a keypress. Since I do not want to parse the interrupt handler, I have another idea.

### Second try: Break at syscall ###  
After trying to break during the cpu core is idling, the next obvious step is to break during a function necessary for handling the keyphrase. Here the "write" syscall is quite useful, since it is used quite often. So I print the syscall table and use [this](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#x86_64-64_bit) webpage to determine the offset of the *write* function -> The offset is **2** and since we have 64-bit addresses, it is the second address. 

```console
(gdb) x/255x (unsigned long*) sys_call_table 
0xffffffff82200300 <sys_call_table>:	0x8138d420	0xffffffff	0x8138d550	0xffffffff
0xffffffff82200310 <sys_call_table+16>:	0x81389010	0xffffffff	0x81386b70	0xffffffff
0xffffffff82200320 <sys_call_table+32>:	0x81393740	0xffffffff	0x81393ef0	0xffffffff
0xffffffff82200330 <sys_call_table+48>:	0x81393980	0xffffffff	0x813a98d0	0xffffffff
0xffffffff82200340 <sys_call_table+64>:	0x81389c90	0xffffffff	0x81044c50	0xffffffff
0xffffffff82200350 <sys_call_table+80>:	0x81307f10	0xffffffff	0x81303670	0xffffffff
0xffffffff82200360 <sys_call_table+96>:	0x813049e0	0xffffffff	0x810d62d0	0xffffffff
```

So the address of the syscall *write* is 0xffffffff8138d550. In the System.map the function is called *__x64_sys_write*.
While breaking at this address and analyzing the results, I realised two things:  
First: It would have been much more efficient to just break at the *entry_SYSCALL_64*, which handles an user-level syscall.
Second: The keyphrase handling is probably done in user-space. So modifing the kernel would work, but it is probablly much easier, to just manipulate a programm used in user space.
Which brings up the nexdt question: Where on the /boot partition are programm stored? I have not found any until now.

### Third try: Read the dmesg output ###
An good approach would be trying to understand the boot process of linux (eventhough it's kind of boring).  
But here we are, reading the dmesg output. To get easy access to the dmesg output we first have to convince the vm to print the output in the console during the startup sequenze. To make this happen, we not only need to modify our VM-Startscript, but make changes to the grub of the VM aswell.
The second step is achived by modifing the /etc/default/grub and add "console=ttyS0,57600n8 ignore_loglevel" to the "GRUB_CMDLINE_LINUX_DEFAULT paramters" and "serial --speed=57600 --unit=0 --word=8 --parity=no --stop=1" to the "GRUB_SERIAL_COMMAND" paramters.
