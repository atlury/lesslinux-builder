title LL BigFatFull (Reverse VNC + local GUI)
linux    /EFI/BOOT/LINUX.EFI
initrd   /i311sf.gz
options  ultraquiet=2 security=none xinitrc=/etc/lesslinux/xinitrc_minimal zswap.enabled=1 skipcheck=1 quiet lang=pl ejectonumass=1 skipservices=|installer|xconfgui|roothash|firewall|ssh|mountdrives| hwid=unknown laxsudo=1 toram=1000000 optram=1 swap=none swapsize=0000 uuid=all crypt=all homecont=0000-00000 console=tty2 loop.max_loop=32  x11vnc=|reverse|xyz.domain.abc|
 
