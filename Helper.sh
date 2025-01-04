#!/bin/bash

# Farben für bessere Lesbarkeit
green="\e[32m"
red="\e[31m"
blue="\e[34m"
reset="\e[0m"

# Begrüßung
clear
echo -e "${blue}Willkommen zu meinem Arch Linux Installations-Skript${reset}"

# Funktion, um die Ausführung zu bestätigen
confirm_continue() {
  echo -e "${blue}Drücke J, um fortzufahren:${reset}"
  read -r -n 1 response
  echo ""
  if [[ ! $response =~ ^[Jj]$ ]]; then
    echo -e "${red}Abgebrochen.${reset}"
    exit 1
  fi
}

# Funktion, um Pakete zu installieren
install_packages() {
  local packages=()
  for package in "$@"; do
    echo -e "${blue}Soll $package installiert werden? [j/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Jj]$ ]]; then
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
  echo -e "${blue}CachyOS-AUR-Repos installieren? [j/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Jj]$ ]]; then
    wget https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    sudo ./cachyos-repo.sh
    cd ..
    sudo rm -r cachyos-repo.tar.xz cachyos-repo
    sudo pacman -S --noconfirm cachyos-settings
  fi
}

# Funktion, um Chaotic-AUR-Repository hinzuzufügen
install_chaotic_repo() {
  echo -e "${blue}Chaotic-AUR-Repos installieren? [j/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Jj]$ ]]; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

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
  echo -e "${blue}CachyOS Kernel Manager installieren? [j/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Jj]$ ]]; then
    sudo pacman -S --noconfirm cachyos-kernel-manager
  fi

  echo -e "${blue}CachyOS Gaming Meta (Proton, Steam, Lutris, Heroic Game Launcher, Wine) installieren? [j/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Jj]$ ]]; then
    sudo pacman -S --noconfirm proton steam lutris heroic-games-launcher wine
  fi

  echo -e "${blue}CachyOS Open NVIDIA Treiber installieren? [j/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Jj]$ ]]; then
    sudo pacman -S --noconfirm linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
  fi

  echo -e "${blue}Empfohlene Software installieren (yay, ufw, fzf, python, python-pip, bluez, blueman, bluez-utils, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)? [j/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Jj]$ ]]; then
    sudo pacman -S --noconfirm yay ufw fzf python python-pip bluez blueman bluez-utils zram-generator fastfetch preload flatpak git wget gedit thermald
    sudo systemctl enable bluetooth ufw preload
  fi

  echo -e "${blue}Benutzt du KDE oder GNOME? [k/g]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Kk]$ ]]; then
    echo -e "${blue}Dolphin installieren? [j/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Jj]$ ]]; then
      sudo pacman -S --noconfirm dolphin
    fi
  elif [[ $response =~ ^[Gg]$ ]]; then
    echo -e "${blue}GNOME Tweaks installieren? [j/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Jj]$ ]]; then
      sudo pacman -S --noconfirm gnome-tweaks
    fi
  fi
}

# Start
confirm_continue
install_cachyos_repo
install_chaotic_repo
install_specific_software

sleep 2
echo -e "${blue}Ändere deine Bootloader-Konfiguration manuell, um den neu installierten Kernel zu booten. Weiter mit J:${reset}"
read -r -n 1 response
if [[ $response =~ ^[Jj]$ ]]; then
  echo -e "${green}Fertig!${reset}"
else
  echo -e "${red}Abgebrochen.${reset}"
fi
