# VFIO.Virt-Manager.

This repository aims to try to alleviate the difficulty of virtualization with passthrough of GPU/USB/Disks and the like, it is extremely IMPORTANT that you read [here](#dependencies-and-minimum-requirements) the dependencies and minimum and recommended requirements for the operation of the machine!  

__*I'm having bad sleep, if you see this message... know that the guide is INCOMPLETE AND NOT FUNCTIONAL UNTIL THEN.*__

> [!WARNING]
> So remember... each experience and situation is unique, it may work or it may not work, in which case I strongly recommend opening an [issue](https://github.com/sakaki91/VFIO.Virt-Manager/issues)!  
> EVERYTHING in this guide has been tested in the following configuration:

    OS: Fedora 43 Workstation (HOST).
    OS: Windows 11 Ghostspectre (GUEST).  
    CPU: i7 9700 (4 CORES GUEST).  
    GPU 0: Intel UHD Graphics 630 (HOST).  
    GPU 1: NVIDIA GTX970 # Driver 580.119.02 (GUEST).  
    SSD: 120GB (HOST).  
    SSD: 120GB (GUEST).  

- [[Getting Started]](README.md)
  - [[Dependencies and Minimum Requirements]](#dependencies-and-minimum-requirements)
  - [[Starting]](#starting)

## Dependencies and Minimum Requirements.  

### Minimum Requirements:  

CPU and MOBO with __VT-d__ and __IOMMU support__, and with *"detach the video"* support.  
You need to go to the __Video/PCI__ settings in the __BIOS__ and activate the integrated video and use the __IGFX__ option and plug the video cable into the motherboard instead of the GPU.  

### Recommended Requirements:

CPU x86_64 with at least 8 cores (so we can allocate at least 4 cores).  
At least 16GB of RAM (so we can allocate at least 8GB of RAM).  
If you have a free SSD or space on your host disk, I strongly recommend using it instead of an HDD, in my case I have 2 SSDs, both 120GB, one for the Host and the other for the Guest.  
My host was rendered using Intel UHD Graphics, as the NVIDIA GTX970 was left over... it was the gpu that I used for this, if you use it from another manufacturer it will be necessary to adapt it to the equivalent modules.  

### Dependencies:  

    $ sudo dnf install virt-manager virt-install libvirt bridge-utils qemu-kvm

If you don't use Fedora... you will need to adapt the commands or package names to their equivalents.  
Then activate the __libvirtd__ module:  

    $ sudo systemctl enable --now libvirtd

## Starting

Starting we will add this following line to grub (/etc/default/grub).

Initially we will go to the grub configuration

    $ sudo nano /etc/default/grub

but be VERY CAREFUL in this area, do not delete anything in this area, just a space and add the new instructions.  

    $ GRUB_CMDLINE_LINUX="quiet intel_iommu=on iommu=pt"

and then restart the PC, enter BIOS and CPU settings, activate VT-d (usually it is activated, but it is better to be sure), and activate IGFX and Internal Graphics in PCI settings (and place the video cable on the motherboard), and run the following command to see if IOMMU is activated.  

    $ sudo dmesg | grep -e DMAR -e IOMMU

Next we will use nano to configure the following:

    $ sudo nano /etc/libvirt/qemu.conf

and add the following lines (and obviously replace the "user" with your user:

    user = "user"
    group = "user"

Now we will Blacklist the NVIDIA Modules, and along with this we will configure the replacements, so that they can release this to the VM  

    $ sudo nano /etc/modprobe.d/blacklist.conf

and add:

      blacklist nouveau  
	  blacklist nvidia  
	  blacklist nvidia_drm  
	  blacklist nvidia_modeset  

and now we will activate the following:

    $ sudo nano /etc/modules-load.d/vfio.conf

and  

    $ sudo nano /etc/modprobe.d/vfio.conf

HOWEVER, FROM HERE ON IT REQUIRES MORE ATTENTION, we will need to find out the ID of your GPU.
To do this we will use the following command (use the equivalent of the drivers you use):  

    $ lspci -nnk | grep -i nvidia -A3  

in my case it returned this, usually the ID, it is the values ​​between [], in my case it is __10de:13c2 and 10de:0fbb__:

    01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204 [GeForce GTX 970] [10de:13c2] (rev a1)
	  Subsystem: Gigabyte Technology Co., Ltd Device [1458:367a]
	  Kernel driver in use: nvidia
	  Kernel modules: nouveau, nvidia_drm, nvidia
    01:00.1 Audio device [0403]: NVIDIA Corporation GM204 High Definition Audio Controller [10de:0fbb] (rev a1)
	  Subsystem: Gigabyte Technology Co., Ltd Device [1458:367a]
	  Kernel driver in use: snd_hda_intel
	  Kernel modules: snd_hda_intel

After we discover this, we will paste the following into the text editor in /etc/modprobe.d/vfio.conf that we opened above:

    options vfio-pci ids=10de:13c2,10de:0fbb

Obviously after the "ids=" you need to put the ID's of your GPU.  
and finally just run one:  

    $ sudo dracut -f

After that, restart your PC and run:

    $ lspci -nnk | grep -i nvidia -A3

in this case, the drivers in use MUST be:

    01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204 [GeForce GTX 970] [10de:13c2] (rev a1)  
    Subsystem: Gigabyte Technology Co., Ltd Device [1458:367a]  
    Kernel driver in use: vfio-pci  
    Kernel modules: nouveau, nvidia_drm, nvidia  
    01:00.1 Audio device [0403]: NVIDIA Corporation GM204 High Definition Audio Controller [10de:0fbb] (rev a1)  
    Subsystem: Gigabyte Technology Co., Ltd Device [1458:367a]  
    Kernel driver in use: vfio-pci  
    Kernel modules: snd_hda_intel  

If this returns... SUCCESS! Now just install the Guest Operating System!  
the guide will be updated, and in the future I will add more tabs so that it can be simpler, including involving the virt-manager interface, along with updating the script in a "neutral" way.
