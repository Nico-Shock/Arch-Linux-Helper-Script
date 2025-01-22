#!/bin/bash

red="\e[31m"
blue="\e[34m"
reset="\e[0m"

trap "echo -e '${red}Script aborted.${reset}'; exit 1" SIGINT
set -e

ask_user() {
  local prompt="$1" var_name="$2"
  while true; do
    echo -e "${blue}${prompt} [y/n]:${reset}"
    read -r -n 1 response
    echo ""
    case "${response,,}" in
      y) eval "$var_name=true"; break ;;
      n) eval "$var_name=false"; break ;;
      *) echo -e "${blue}INVALID INPUT. PLEASE TRY AGAIN. [y/n]:${reset}" ;;
    esac
  done
}

install_packages() {
  local packages=("$@")
  [ ${#packages[@]} -gt 0 ] && sudo pacman -S --needed "${packages[@]}"
}

install_cachyos=false
install_chaotic=false
install_kernel_manager=false
install_gaming_meta=false
install_open_nvidia_driver=false
install_closed_nvidia_dkms_driver=false
install_recommended_software=false
install_dolphin=false
install_gnome_tweaks=false
install_new_kernel=false

clear
sudo pacman -Syu
clear

ask_user "Do you want to install the CachyOS repos?" install_cachyos
ask_user "Do you want to install the Chaotic-AUR-repos?" install_chaotic
ask_user "Do you want to install the CachyOS Kernel Manager?" install_kernel_manager
ask_user "Do you want to install the CachyOS Gaming Meta?" install_gaming_meta
ask_user "Do you want to install Nvidia open drivers?" install_open_nvidia_driver

if ! $install_open_nvidia_driver; then
  ask_user "Do you want to install Nvidia closed source drivers?" install_closed_nvidia_dkms_driver
fi

ask_user "Do you want to install recommended software? (yay, ufw, fzf, python, python-pip, bluez, blueman, bluez-utils, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)" install_recommended_software

echo -e "${blue}Do you use KDE or Gnome? [k/g/n]:${reset}"
read -r -n 1 desktop_env
echo ""

while [[ ! "$desktop_env" =~ ^[kgnKGN]$ ]]; do
  echo -e "${blue}INVALID INPUT. PLEASE TRY AGAIN. [k/g/n]:${reset}"
  read -r -n 1 desktop_env
  echo ""
done

[[ $desktop_env =~ [kK] ]] && ask_user "Do you want to install Dolphin?" install_dolphin
[[ $desktop_env =~ [gG] ]] && ask_user "Do you want to install Gnome Tweaks?" install_gnome_tweaks

ask_user "Do you want to install a new linux kernel?" install_new_kernel

if $install_new_kernel; then
  echo -e "PLEASE SELECT THE NUMBER FOR THE KERNEL YOU WANT TO INSTALL:"
  echo -e "1. linux-cachyos"
  echo -e "2. linux-cachyos-rc"
  echo -e "3. linux-vfio"
  read -r -n 1 kernel_choice
  echo ""

  case $kernel_choice in
    1)
      sudo pacman -S --noconfirm linux-cachyos linux-cachyos-headers
      ;;
    2)
      sudo pacman -S --noconfirm linux-cachyos-rc linux-cachyos-rc-headers
      ;;
    3)
      sudo pacman -S --noconfirm linux-vfio linux-vfio-headers
      ;;
    *)
      echo -e "${blue}INVALID INPUT. PLEASE TRY AGAIN. [1/2/3]:${reset}"
      exit 1
      ;;
  esac
fi

if $install_cachyos; then
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz &&
  tar xvf cachyos-repo.tar.xz &&
  cd cachyos-repo &&
  sudo ./cachyos-repo.sh &&
  cd .. &&
  rm -rf cachyos-repo cachyos-repo.tar.xz &&
  sudo pacman -S cachyos-settings
fi

if $install_chaotic; then
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
  sudo pacman-key --lsign-key 3056513887B78AEB &&
  sudo pacman -U https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst &&
  sudo pacman -U https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst &&
  grep -q 'chaotic-aur' /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf &&
  sudo pacman -Sy
fi

if $install_kernel_manager; then
  sudo pacman -S cachyos-kernel-manager
fi

if $install_gaming_meta; then
  sudo pacman -S cachyos-gaming-meta
fi

if $install_open_nvidia_driver; then
  sudo pacman -S linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
fi

if $install_closed_nvidia_dkms_driver; then
  sudo pacman -S nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings linux-headers
  sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
  sudo mkdir -p /etc/pacman.d/hooks
  sudo bash -c 'cat > /etc/pacman.d/hooks/nvidia.hook <<EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia

[Action]
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF'
fi

if $install_recommended_software; then
  install_packages yay ufw fzf python python-pip bluez blueman bluez-utils zram-generator fastfetch preload flatpak git wget gedit thermald
  sudo systemctl enable --now ufw bluetooth preload
fi

sudo pacman -Scc
exit 0
