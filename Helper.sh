#!/bin/bash

green="\e[32m"
red="\e[31m"
blue="\e[34m"
reset="\e[0m"

clear
echo -e "${blue}Welcome to my Arch Linux Installation Script${reset}"

confirm_continue() {
  echo -e "${blue}Press Y to continue or any other key to abort:${reset}"
  read -r -n 1 response
  echo ""
  if [[ ! $response =~ ^[Yy]$ ]]; then
    echo -e "${red}Aborted.${reset}"
    exit 1
  fi
}

install_packages() {
  local packages=()
  for package in "$@"; do
    echo -e "${blue}Do you want to install $package? [Y/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
      packages+=("$package")
    fi
  done

  if [ ${#packages[@]} -eq 0 ]; then
    echo -e "${red}No packages selected.${reset}"
  else
    echo -e "${green}The following packages will be installed: ${packages[*]}${reset}"
    confirm_continue
    sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi
}

install_cachyos_repo() {
  echo -e "${blue}Do you want to install the CachyOS AUR repositories? [Y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
    confirm_continue
    wget https://mirror.cachyos.org/cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz && cd cachyos-repo
    sudo ./cachyos-repo.sh
    cd ..
    sudo rm -r cachyos-repo.tar.xz cachyos-repo
    sudo pacman -S --noconfirm cachyos-settings
  fi
}

install_chaotic_repo() {
  echo -e "${blue}Do you want to install the Chaotic-AUR repositories? [Y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
    confirm_continue
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    sudo sed -i '$d' /etc/pacman.conf
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
  fi
}

install_specific_software() {
  echo -e "${blue}Do you want to install the CachyOS Kernel Manager? [Y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
    confirm_continue
    sudo pacman -S --noconfirm cachyos-kernel-manager
  fi

  echo -e "${blue}Do you want to install the CachyOS Gaming Meta (Proton, Steam, Lutris, Heroic Game Launcher, Wine)? [Y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
    confirm_continue
    sudo pacman -S --noconfirm proton steam lutris heroic-games-launcher wine
  fi

  echo -e "${blue}Do you want to install the CachyOS Open NVIDIA Drivers? [Y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
    confirm_continue
    sudo pacman -S --noconfirm linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
  fi

  echo -e "${blue}Do you want to install recommended software (yay, ufw, fzf, python, python-pip, bluez, blueman, bluez-utils, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)? [Y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
    confirm_continue
    sudo pacman -S --noconfirm yay ufw fzf python python-pip bluez blueman bluez-utils zram-generator fastfetch preload flatpak git wget gedit thermald
    sudo systemctl enable bluetooth ufw preload
  fi

  echo -e "${blue}Do you use KDE or GNOME? [k/g]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Kk]$ ]]; then
    echo -e "${blue}Do you want to install Dolphin? [Y/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
      confirm_continue
      sudo pacman -S --noconfirm dolphin
    fi
  elif [[ $response =~ ^[Gg]$ ]]; then
    echo -e "${blue}Do you want to install GNOME Tweaks? [Y/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
      confirm_continue
      sudo pacman -S --noconfirm gnome-tweaks
    fi
  fi
}

confirm_continue
install_cachyos_repo
install_chaotic_repo
install_specific_software

sleep 2
echo -e "${blue}Manually change your bootloader configuration to boot the newly installed kernel. Press Y to continue:${reset}"
read -r -n 1 response
echo ""
if [[ $response =~ ^[Yy]$ || $response == "" ]]; then
  echo -e "${green}Done!${reset}"
else
  echo -e "${red}Aborted.${reset}"
fi
