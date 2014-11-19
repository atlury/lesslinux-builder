This repository contains the scripts used for building LessLinux. They are not complete yet since I am cleaning up during the move from subversion to git. See the documentation on http://blog.lesslinux.org/ for details. 

## Today's state 

**Legacy: Green** Build with and `--legacy` - this uses headers and kernels from the 3.14.24 LTS series. Firefox 31.2.0esr has some issues building the portuguese language pack. No complete build with 3.14.24 has been done yet, but I expect no surprises.

**Stable: Yellow** Building with 3.17.3 is partially tested. Firefox 33.1.1 has some issues building the russian, portuguese and polish language packs.

**Unstable: Red** libpng 1.6.14 has been added and should automatically be selected by most programs that formerly used libpng 1.5.x. cmake has been updated to 3.0.2, but not yet tested in a full build. pkg_content for boost and some other updated packages is missing.

## Checking out

Checking out under LessLinux Jabba Builds may fail due to missing certificates, use the command: 

`git -c http.sslVerify=false clone https://github.com/mschlenker/lesslinux-builder` 

## Building the Toolchain

Scripts for the toolchain reside in stage01. This basically builds cross compile tools that are native to the host architecture. It is later used to chroot to. For details read http://www.linuxfromscratch.org/lfs/view/development/chapter05/introduction.html.

To build, simply run: 

`ruby -I. builder.rb -n -l -s 2,3`

This skips the second and third stage, logs and runs no tests. If you want to build the unstable tree, use:

`ruby -I. builder.rb -n -l -s 2,3 -u`

To determine if you have to use unstable or not to build as close as possible certain release, take a look at the files `/etc/lesslinux/updater/version.git` and `/etc/lesslinux/updater/command.sh`. The first file contains the git SHA1 sum that identifies a certain revision und the second contains the stage 3 command.

## Building packages in chroot

Now packages in the chroot have to be build. LessLinux supports parallel builds (`-t`) and dependency tracking using strace. If you are not adding new packages, turn it off.

To build, simply run: 

`ruby -I. builder.rb -n -l -s 1,3 -t 3 --no-stracalyze`

or 

`ruby -I. builder.rb -n -l -s 1,3 -t 3 --no-stracalyze -u`

## Building the final ISO image

To build the ISO you have to specify some config paths - you might use modified versions of those config files outside the LessLinux tree - copy the command from `/etc/lesslinux/updater/command.sh` mentioned above:

	ruby -I. builder.rb -n -s 1,2,bootconf \
	  -p config/pkglist_neutral_rescue_GTK3.txt \
	  --skip-files config/skiplist_neutral_rescue.txt \
	  -c config/general_neutral_rescue.xml \
	  -b config/branding_neutral_rescue.xml \
	  -k config/kernels_rescue_experimental.xml -u
 
