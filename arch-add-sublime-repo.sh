## Install Sublime's Pacman repo in Arch

# Get the GPG key
curl -O https://download.sublimetext.com/sublimehq-pub.gpg && pacman-key --add sublimehq-pub.gpg && pacman-key --lsign-key 8A8F901A && rm sublimehq-pub.gpg

# Add the repo to pacman.conf
echo -e "\n[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64" | tee -a /etc/pacman.conf

# Sync package list
pacman -Sy

# Friendly and informative completion message
echo
echo "* Done! You can now install the 'sublime-text' package. Hooray!"
echo