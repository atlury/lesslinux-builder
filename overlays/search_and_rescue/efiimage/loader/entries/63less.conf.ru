title LL Search and Rescue (Reverse VNC + local GUI)
linux    /EFI/BOOT/LINUX.EFI
initrd   /EFI/idefsf.gz
options  ultraquiet=3 security=none zswap.enabled=1 skipcheck=1 quiet lang=ru ejectonumass=1 skipservices=|earlynet|dhcpcd|installer|xconfgui|roothash|firewall|ssh|mountdrives| hwid=unknown laxsudo=1 toram=1000000 optram=1 swap=none swapsize=0000 blobsize=2048 uuid=all crypt=all homecont=0000-00000 console=tty2 loop.max_loop=32  x11vnc=|reverse|xyz.domain.abc|
 
