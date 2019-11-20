
PKGS=(
base base-devel linux-hardened net-tools bind-tools iw openssh rsync mtr nmap whois iptraf-ng lftp curl wget aria2 lynx links ruby-docs xorg xfce4 xfce4-goodies 
xorg-apps xorg-fonts gnome-themes-standard qemu fuse sshfs fuseiso mpv ffmpeg pulseaudio pavucontrol volumeicon audacious chromium meld htop tree nano vim git ruby python 
wpa_supplicant ferm zip unzip p7zip unace unrar pigz pixz tree pv the_silver_searcher fzf fortune-mod ncdu dhex arch-audit pkgfile axel xclip wmctrl xdotool perl-term-readkey meld 
postgresql syslinux git tmux iucode-tool intel-ucode dialog dmenu youtube-dl dillo bat yajl redshift jq cmake go zathura djvulibre nodejs npm engrampa caja feh cpio lua luajit 
expect fd termite sox hwinfo nim nimble rust ipython libisoburn evince dolphin gst-plugins-bad gst-plugins-ugly phonon-qt5-gstreamer yasm subversion gperf xorg-xeyes 
dstat asp wv imagemagick ctags gparted binwalk arj cabextract mtd-utils squashfs-tools lhasa inkscape qt5ct oxygen qutebrowser ffmpegthumbs kdegraphics-thumbnailers 
doxygen zim vlc calibre libxdg-basedir audacity gthumb strace xdot rofi wireless_tools pacman-contrib gsmartcontrol httpie terminus-font gstreamer gst-libav ffmpegthumbnailer
)

pacstrap /mnt ${PKGS[@]}
