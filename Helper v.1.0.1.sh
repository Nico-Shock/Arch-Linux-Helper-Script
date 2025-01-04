#!/bin/bash

green="\e[32m"
red="\e[31m"
blue="\e[34m"
reset="\e[0m"

trap "echo -e '${red}Script aborted.${reset}'; exit 1" SIGINT

ask_user() {
  local prompt="$1"
  local var_name="$2"
  echo -e "${blue}${prompt} [y/n]:${reset}"
  read -r -n 1 response
  echo ""
  if [[ $response =~ ^[Yy]$ ]]; then
    eval "$var_name=true"
  else
    eval "$var_name=false"
  fi
}

install_packages() {
  local packages=("$@")
  if [ ${#packages[@]} -ne 0 ]; then
    echo -e "${green}The following packages will be installed: ${packages[*]}${reset}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi
}

install_cachyos=false
install_chaotic=false
install_kernel_manager=false
install_gaming_meta=false
install_nvidia_drivers=false
install_recommended_software=false
install_dolphin=false
install_gnome_tweaks=false

clear
echo -e "${blue}Welcome to the Arch Linux post installation script${reset}"

ask_user "Do you want to install the CachyOS repos?" install_cachyos
ask_user "Do you want to install the Chaotic-AUR-repos?" install_chaotic
ask_user "Do you want to install the CachyOS Kernel Manager?" install_kernel_manager
ask_user "Do you want to install the CachyOS Gaming Meta (Proton, Steam, Lutris, Heroic Games Launcher, Wine – idk the exact package names)" install_gaming_meta
ask_user "Do you want to install Nvidia open drivers (linux-cachyos-nvidia-open, libglvnd, nvidia-utils, opencl-nvidia, lib32-libglvnd, lib32-nvidia-utils, lib32-opencl-nvidia, nvidia-settings)?" install_nvidia_drivers
ask_user "Do you want to install recommended software (yay, ufw, fzf, python, python-pip, bluez, blueman, bluez-utils, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)?" install_recommended_software

echo -e "${blue}Do you use KDE or Gnome? [k/g/n]:${reset}"
read -r -n 1 desktop_env
echo ""
if [[ $desktop_env =~ ^[Kk]$ ]]; then
  ask_user "Do you want to install Dolphin?" install_dolphin
elif [[ $desktop_env =~ ^[Gg]$ ]]; then
  ask_user "Do you want to install Gnome Tweaks?" install_gnome_tweaks
fi

echo -e "${blue}Starting installation based on your responses...${reset}"

if $install_cachyos; then
  echo -e "${green}Adding CachyOS repository...${reset}"
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz &&
  tar xvf cachyos-repo.tar.xz &&
  cd cachyos-repo &&
  sudo ./cachyos-repo.sh &&
  cd .. &&
  rm -rf cachyos-repo cachyos-repo.tar.xz &&
  sudo pacman -S --noconfirm cachyos-settings
fi

if $install_chaotic; then
  echo -e "${green}Adding Chaotic-AUR repository...${reset}"
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
  sudo pacman-key --lsign-key 3056513887B78AEB &&
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst &&
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst &&
  grep -q 'chaotic-aur' /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf &&
  sudo pacman -Sy
fi

if $install_kernel_manager; then
  echo -e "${green}Installing CachyOS Kernel Manager...${reset}"
fi

if $install_gaming_meta; then
  echo -e "${green}Installing CachyOS Gaming Meta...${reset}"
fi

if $install_nvidia_drivers; then
  echo -e "${green}Installing NVIDIA open drivers...${reset}"
fi

if $install_recommended_software; then
  echo -e "${green}Installing recommended software...${reset}"
fi

if $install_dolphin; then
  echo -e "${green}Installing Dolphin...${reset}"
fi

if $install_gnome_tweaks; then
  echo -e "${green}Installing Gnome Tweaks...${reset}"
fi

echo -e "${green}Script completed.${reset}"
exit 0
