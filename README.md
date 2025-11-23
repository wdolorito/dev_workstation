# devuan excalibur with suckless git dwm + co

### some nonsense
My goto distro has always been Debian, but sometimes I just don't want to deal with ```systemd```.  Enter Devuan.  All that stable (read old) software, minus the complexities of that other init system.

Don't get me wrong, I don't care much about what init system is in use, all my dailies default boot in to Debian, and systemd really isn't that hard to administer.  What's nice is that Devuan is noticeably faster on my aging fleet of increasingly outdated computer hardware, especially in containers and VMs.  These are my notes, reminders and support scripts regarding installation on to a laptop workstation.

These files have mostly been ripped from my deb_workstation (https://github.com/wdolorito/deb_workstation.git) repo, and bits and pieces taken and inspired from the other two repos for Chimera Linux (https://github.com/wdolorito/chimera_workstation.git) and Voidlinux (https://github.com/wdolorito/void_workstation.git).

Different from the other set of instructions, this one ditches all wayland related everything for the ```dwm``` (https://dwm.suckless.org/) window manager and its supporting software.  Namely, ```st``` for the terminal emulator, ```dmenu``` for launching programs and ```slstatus``` for a status bar.  A few convenience patches are used and compiled using ```clang``` to be installed in the user's home directory.  All automagically downloaded and compiled from source with a script.

There is really no reason why these instructions exist, just that it could be done.  What's actually nice is that KiCad won't be a problem to install from flathub (unlaunchable without Xwayland support).  What's not that nice is that unprivileged containers don't work as expected without systemd, requiring to be run as root.  I'm sure there's a solution to that, since it works perfectly well under Debian, but I honestly haven't looked too deep in to it since I can just take a few seconds to boot Debian if I need a user container for a development DB for instance.  Or just use the containers I set up on my Debian server on my local network.

That all said, I really do love the not jumping over the hoops and hurdles using pure wayland.  Which, to the project's credit, are becoming fewer and far between.  It also brings me back to my earliest days of linux use futzing with sysvinit scripts to get things to run and messing with xorg files to get a graphical desktop.  In short, everything works (for me), and it was fun setting all this up.
## start with basic excalibur netinstall (https://www.devuan.org/get-devuan)
### install packages
#### as root:
```
grep ^# -v packages | sed '/^s*$/d' | xargs apt install
cp <path to repo>/root_files/30-touchpad.conf /etc/X11/xorg.conf.d
cp <path to repo>/root_files/doas.conf /etc
cp <path to repo>/root_files/sources.list /etc/apt
apt-get update
apt-get -y dist-upgrade
apt-get -y autoremove --purge
apt-get -y autoclean
apt-get -y clean
dpkg -l | grep ^rc | awk '{print $2}' | xargs apt-get purge -y
```
* check ```pacakges``` file for additional comments/directions
* after adding a user (```adduser/useradd```), add user to basic groups
```
usermod -aG <user> $(cat <path to repo>/root_files/user_groups.txt)
sed -i 's/<user>/<your user>/g' /etc/doas.conf
```

### networking
* strip out all interfaces except localhost
```
cp <path to repo>/root_files/interfaces /etc/network
# enable and start iwd (if using wifi)
update-rc.d iwd enable
service iwd start
# setup wifi
iwctl station wlan0 connect <SSID> # wait for Passphrase prompt
dhclient -v wlan0
```
* connected SSID will automatically connect on reboot
* user will able to use ```dhclient``` via doas and support script ```~/local/bin/dhclient```
* user will able to use ```iwctl``` via group permissions
* add a definition to ```/etc/network/interfaces.d``` for a wired interface (if present)
```
#
# /etc/network/interfaces.d/eth0
#

allow-hotplug eth0
iface eth0 inet dhcp
```
* if wired interface is not present at boot, prepare to wait until timeout
* ```iwd``` service starts after ```networking``` service during boot
* do not add wireless interface definition for this reason
### setup user paths + login
#### as user:
```
cd # switch to home directory
for patch in <path to repo>/user_files/*.patch ; do patch < "$patch" ; done
cp -r <path to repo>/dots/.config ~/
cp -r <path to repo>/dots/.ssh ~/
cp <path to repo>/dots/.fbtermrc ~/
cp <path to repo>/dots/.gitconfig ~/
cp <path to repo>/dots/.xinitrc ~/
cp <path to repo>/local ~/
cp <path to repo>/suckless ~/.local
```
* edit ```~/.gitconfig``` with personal information
* create user ssh keys per instructions in ```~/.ssh/config```
* log out, log back in and continue
### setup flatpak apps
```
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak --user remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
```
* flathub repos (https://flathub.org/en)
```
for app in $(cat flatpak_apps.txt) ; do flatpak install flathub -y --noninteractive "$app" ; done
```
* when prompted for extensions (llvm, node, openjdk), install runtime used by codium
```
flatpak info com.vscodium.codium | grep Runtime | awk -F / '{print $(NF)}'
```

### codium setup
```
for extension in $(cat codium_extensions.txt) ; do codium --install-extension "$extension" ; done
flatpak --user override --env="FLATPAK_ENABLE_SDK_EXT=llvm20,node24,openjdk21" com.vscodium.codium
```
#### additional codium setup
* start codium
* enter settings
* search 'default profile'
* change to 'bash'
* search 'ttyusb'
* change to /dev/ttyUSB0

### misc utils
* toggle screenlocker on and off
```
toggle_lock
```
* toggle wireless on and off
```
toggle_airplane
```
* generate script files for flatpak apps that dmenu can see
* run after adding/removing flatpak apps
```
gen_fpbins
```
* script files will be generated in ```"$HOME/.local/fpbin"```, which gets forcibly removed and recreated on run if it exists
* add apps not desired to appear in the ```test_appname()``` case section of the script

### jumping in to a graphical session
* compile dwm + co:
```
cd ~/.local/suckless/suckless-conf
sed -i 's/<user>/<your user>/g' slstatus-config.h # * inspect file for workstation specific settings
cd ..
./compile_suckless.sh
```
* uncomment and set background wallpaper in ```.xinitrc``` (line that starts with ```#feh```)
* start graphical session
```
start_dwm
```
