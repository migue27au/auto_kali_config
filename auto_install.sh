### AUTO INSTALL KALI PACKAGES ###

function log {
    symbol=$1
    text=$2
    
    # Colores en negrita
    BOLDRED="\e[1;31m"
    BOLDGREEN="\e[1;32m"
    BOLDYELLOW="\e[1;33m"
    BOLDMAGENTA="\e[1;35m"
    END="\e[0m" # Resetear los estilos y colores

    case $symbol in
        "+")
            echo -e "${BOLDGREEN}[+]${END} ${text}"
            ;;
        "-")
            echo -e "${BOLDRED}[-]${END} ${text}"
            ;;
        "!")
            echo -e "${BOLDYELLOW}[!]${END} ${text}"
            ;;
        "v")
            echo -e "${BOLDMAGENTA}[v]${END} ${text}"
            ;;
        *)
            echo -e "${BOLDRED}${text}${END}" # Mensaje por defecto en rojo
            ;;
    esac
}

whoami=$(whoami)
if [[ $whoami != "root" ]]; then
    log "-" "Run this with sudo"
    exit 1
fi


AUTO_KALI_CONFIG_REPO="https://raw.githubusercontent.com/migue27au/auto_kali_config/main/"

TEMP_FOLDER="/tmp/auto_kali_configuration/"
log "!" "Creating temporal folder: $TEMP_FOLDER"
mkdir -p $TEMP_FOLDER

log "!" "Getting system users"
users=($(awk -F: '$6 ~ /^\/home/ { print $1 }' /etc/passwd))
log "+" "Users: $users"


# ADDING SPOTIFY DEBIAN REPOSITORY
log "+" "Adding Spotify repository"
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list


# ADDING SUBLIME DEBIAN REPOSITORY
log "+" "Adding Sublime text repository"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list

# ADDING CHROME DEBIAN REPOSITORY
log "+" "Adding Chrome repository"
wget -qO - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/trusted.gpg.d/google-chrome.gpg > /dev/null
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# ADDING BRAVE DEBIAN REPOSITORY
log "+" "Adding Brave browser repository"
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list

log "+" "Update repository"
apt update

log "!" "Upgrade all packages"
apt upgrade

log "+" "Update repository"
apt update


log "+" "Installing build-essential and linux-headers"
apt install build-essential linux-headers-$(uname -r) -y

# INSTALING LINUX ESSENTIAL AND LINUX  HEADERS

# Array de paquetes a instalar
packages=(
    "spotify-client"
    "sublime-text"
    "brave-browser"
    "openvpn-systemd-resolved"
    "flameshot"
    "xfce4-terminal"
    "adb"
    "dbus-x11"
    "sshpass"
    "spotify-client"
    "google-chrome-stable"
    "sublime-text"
    "dirmngr"
    "gnupg"
    "snapd"
    "tldr"
    "flameshot"
    "bloodhound"
    "keepass2"
    "golang"
    "xfce4-genmon-plugin"
    "gimp"
    "vlc"
    "audacity"
    "bat"
    "docker-ce"
    "docker-ce-cli"
    "docker-compose"
    "containerd.io"
    "bettercap"
    "hostapd"
    "mdk4"
    "asleap"
    "isc-dhcp-server"
    "hostapd-wpe"
    "hcxdumptool"
    "hcxtools"
    "beef-xss"
    "lighttpd"
    "openvpn-systemd-resolved"
    "libreoffice"
    "seclists"
)

while [ $i -lt ${#packages[@]} ]; do
    package=${packages[$i]}
    log "+" "Installing $package"

    # Intentar instalar el paquete
    apt install -y $package

    # Comprobar si ocurrió un error
    if [ $? -ne 0 ]; then
        log "-" "Error installing $package. Trying apt install --fix-missing to solve it"
        apt install -y
        apt install --fix-missing -y

        apt install -y $package
    fi

    ((i++))
done


log "+" "Downlading xfce4 panel configuration"
wget -P $TEMP_FOLDER "$AUTO_KALI_CONFIG_REPO/xfce4-panel.xml"
wget -P $TEMP_FOLDER "$AUTO_KALI_CONFIG_REPO/xfce4-panel.zip"

log "+" "Downloading oh-my-zsh"
wget -O "$TEMP_FOLDER/install-ohmyzsh.sh" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

log "+" "Installing ohmyzsh"
sh "$TEMP_FOLDER/install-ohmyzsh.sh" --unattended

log "+" "Downloading custom oh-my-zsh themes"
wget -P $TEMP_FOLDER "$AUTO_KALI_CONFIG_REPO/root-theme.zsh-theme"
wget -P $TEMP_FOLDER "$AUTO_KALI_CONFIG_REPO/user-theme.zsh-theme"

log "+"  "Downloading custom cherrytree config"
wget -P $TEMP_FOLDER $AUTO_KALI_CONFIG_REPO/cherrytree_config.cfg

log "+" "Copying root-custom-theme into ohmyzsh custom themes folder"
cp "$TEMP_FOLDER/root-theme.zsh-theme" "/root/.oh-my-zsh/custom/themes/my-custom-theme.zsh-theme"

log "+" "Creating users group"
groupadd "users"

for user in "${users[@]}"; do
    log "+" "Configurin user $user"

    log "+" "Adding $user to users group"
    usermod -aG "users" "$user"

    #Copying ohmyzsh files into users dir
    log "+" "Copying ZSH files into /home/$user"
    cp -r /root/.oh-my-zsh "/home/$user/"
    cp -r /root/.zshrc "/home/$user/"
    
    log "+" "Copying custom config cherrytree config folder"
    cp "$TEMP_FOLDER/cherrytree_config.cfg" "/home/$user/.config/cherrytree/config.cfg"

    log "+" "Copying user-custom-theme into ohmyzsh custom themes folder"
    mv "$TEMP_FOLDER/user-theme.zsh-theme" "/home/$user/.oh-my-zsh/custom/themes/my-custom-theme.zsh-theme"

    log "+" "Changing keyboard layout to es"
    setxkbmap es

    log "+" "Configuring shortcuts ctrl+alt+t for xfce4-terminal"
    sudo -u "$user" xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Primary><Alt>t' -t string -s '/usr/bin/xfce4-terminal'

    log "+" "Configuring shortcuts win+shift+s for flameshot gui"
    sudo -u "$user" xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Shift><Super>s' -t string -s '/usr/bin/flameshot gui' --create

    log "+" "Setting SHAPE IBEAM in xfce4-terminal"
    sudo -u "$user" xfconf-query -c xfce4-terminal -p /misc-cursor-shape -s TERMINAL_CURSOR_SHAPE_IBEAM

    log "+" "Setting TRANSPARENCY TO 1.0 in xfce4-terminal"
    sudo -u "$user" xfconf-query -c xfce4-terminal -p /background-darkness -s 1.0

    log "+" "Setting default terminal to xfce4-terminal"
    echo "" > "/home/$user/.config/xfce4/helpers.rc"
    sudo -u "$user" echo "TerminalEmulator=xfce4-terminal" >> "/home/$user/.config/xfce4/helpers.rc"
    update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper
    sudo -u "$user" log "+" "Setting default browser to brave-browser"
    echo "WebBrowser=brave-browser" >> "/home/$user/.config/xfce4/helpers.rc"

    log "+" "Creating tools folder"
    mkdir "/home/$user/Documents/tools"

    log "+" "Downloading pyperclip"
    sudo -u "$user" pip pyperclip --break-system-packages

    log "+" "Downloading my tools"
    sudo -u "$user" git clone https://github.com/migue27au/toolbar_tools "/home/$user/Documents/tools/toolbar/"
    sudo -u "$user" git clone https://github.com/migue27au/nmap-info "/home/$user/Documents/tools/"
    sudo -u "$user" git clone https://github.com/migue27au/ping-sweep "/home/$user/Documents/tools/"
    sudo -u "$user" git clone https://github.com/migue27au/hostager "/home/$user/Documents/tools/"

    log "+" "Giving execution permissions"
    chmod +x "/home/$user/Documents/tools/nmap-info/nmap-info.py"
    chmod +x "/home/$user/Documents/tools/ping-swep/ping-sweep.py"
    chmod +x "/home/$user/Documents/tools/hostager/hostager.py" 
    chmod +x "/home/$user/Documents/tools/toolbar/target.sh" 

    log "+" "Creating symbolic links"
    ln -s "/home/$user/Documents/tools/nmap-info/nmap-info.py" "/home/$user/.local/bin/nmap-info"
    ln -s "/home/$user/Documents/tools/ping-swep/ping-sweep.py" "/home/$user/.local/bin/ping-sweep"
    ln -s "/home/$user/Documents/tools/hostager/hostager.py" "/home/$user/.local/bin/hostager"
    ln -s "/home/$user/Documents/tools/toolbar/target.sh" "/home/$user/.local/bin/target"

    log "+" "Configuring xfce4-panel"
    mv "/home/$user/.config/xfce4/panel" "/tmp/$user_xfce4_panel"
    sudo -u "$user" unzip "$TEMP_FOLDER/xfce4-panel.zip" -d "/home/$user/.config/xfce4/"
    sudo -u "$user" cp "$TEMP_FOLDER/xfce4-panel.xml" -d "/home/$user/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
    sudo -u "$user" xfconf-query -c xfce4-panel -p /plugins/plugin-4/base-directory -s "/home/$user"

    log "+" "Downloading frida & ojection"
    sudo -u "$user" pip install frida frida-tools ojbection uploadserver --break-system-packages

    log "+" "Downloading uploadserver"
    sudo -u "$user" uploadserver --break-system-packages


done

log "+" "Extracting rockyou"
gunzip /usr/share/wordlists/rockyou.txt.gz

log "+" "Downloading airgeddon project"
git clone https://github.com/v1s1t0r1sh3r3/airgeddon /opt/airgeddon
chown -R root:users /opt/airgeddon
chmod -R 770 /opt/airgeddon

log "+" "Downloading proxmark3 project"
git clone https://github.com/RfidResearchGroup/proxmark3 /opt/proxmark3
chown -R root:users /opt/proxmark3
chmod -R 770 /opt/proxmark3

log "!" "Uninstalling modemmanager"
apt remove modemmanager -y

log "+" "Installing proxmark3 project"
cd /opt/proxmark3
make accessrights
make clean && make -j
make install

log "!" "Enabling bluetooth service"
systemctl enable bluetooth

log "!" "Upgrade all packages"
apt update && apt upgrade -y

log "!" "Reboot your system now"
