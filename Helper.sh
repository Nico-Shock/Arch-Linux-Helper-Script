#!/bin/bash

# Farben für bessere Lesbarkeit
green="\e[32m"
red="\e[31m"
blue="\e[34m"
reset="\e[0m"

# Begrüßung
clear
echo -e "${blue}Willkommen zum Arch Linux Installations-Skript!${reset}"

# Funktion, um die Ausführung zu bestätigen
confirm_continue() {
  echo -e "${blue}Press Y to continue: ${reset}"
  read -r response
  if [[ ! $response =~ ^[Yy]$ ]]; then
    echo -e "${red}Abgebrochen.${reset}"
    exit 1
  fi
}

# Funktion, um Pakete zu installieren
install_packages() {
  local packages=()
  for package in "$@"; do
    echo -e "${blue}Soll $package installiert werden? [y/n]: ${reset}"
    read -r response
    if [[ $response =~ ^[Yy]$ ]]; then
      packages+=("$package")
    fi
  done

  if [ ${#packages[@]} -eq 0 ]; then
    echo -e "${red}Keine Pakete ausgewählt.${reset}"
  else
    echo -e "${green}Folgende Pakete werden installiert: ${packages[*]}${reset}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi
}

# Funktion, um CachyOS-Repository hinzuzufügen
install_cachyos_repo() {
  echo -e "${blue}Install CachyOS-AUR-Repos? [y/n]: ${reset}"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    wget https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    sudo ./cachyos-repo.sh
    cd ..
    sudo rm -r cachyos-repo.tar.xz cachyos-repo
    sudo pacman -S cachyos-settings
  fi
}

# Funktion, um Chaotic-AUR-Repository hinzuzufügen
install_chaotic_repo() {
  echo -e "${blue}Install Chaotic-AUR-Repos? [y/n]: ${reset}"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    # Ändern von /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
  fi
}

# Funktion, um spezifische Software zu installieren
install_specific_software() {
  echo -e "${blue}Install CachyOS Kernel Manager? [y/n]: ${reset}"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    sudo pacman -S cachyos-kernel-manager
  fi

  echo -e "${blue}Install CachyOS Gaming Tools (Proton, Steam, Lutris, Heroic Game Launcher, Wine)? [y/n]: ${reset}"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    sudo pacman -S proton steam lutris heroic-games-launcher wine
  fi

  echo -e "${blue}Install CachyOS Open NVIDIA Drivers? [y/n]: ${reset}"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    sudo pacman -S linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
  fi

  echo -e "${blue}Install Recommended Software? [y/n]: ${reset}"
  read -r response
  if [[ $response =~ ^[Yy]$ ]]; then
    sudo pacman -S yay ufw fzf python python-pip bluez blueman bluez-utils zram-generator fastfetch preload
    sudo systemctl enable bluetooth ufw preload
  fi
}

# Start
confirm_continue
install_cachyos_repo
install_chaotic_repo
install_specific_software

echo -e "${blue}Ändere deine Bootloader-Konfiguration manuell, um den neu installierten Kernel zu booten. Continue with Y: ${reset}"
read -r response
if [[ $response =~ ^[Yy]$ ]]; then
  echo -e "${green}Fertig!${reset}"
else
  echo -e "${red}Abgebrochen.${reset}"
fi
