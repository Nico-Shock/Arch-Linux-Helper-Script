#!/bin/bash

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
    sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi
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

clear
echo -e "${blue}Welcome to the Arch Linux post installation script${reset}"

ask_user "Do you want to install the CachyOS repos?" install_cachyos
ask_user "Do you want to install the Chaotic-AUR-repos?" install_chaotic
ask_user "Do you want to install the CachyOS Kernel Manager?" install_kernel_manager
ask_user "Do you want to install the CachyOS Gaming Meta (Proton, Steam, Lutris, Heroic Games Launcher, Wine – idk the exact package names, sorry)" install_gaming_meta
ask_user "Do you want to install Nvidia open drivers (linux-cachyos-nvidia-open, libglvnd, nvidia-utils, opencl-nvidia, lib32-libglvnd, lib32-nvidia-utils, lib32-opencl-nvidia, nvidia-settings)?" install_open_nvidia_driver
ask_user "Do you want to install Nvidia closed source drivers (nvidia-dkms, libglvnd, nvidia-utils, opencl-nvidia, lib32-libglvnd, lib32-nvidia-utils, lib32-opencl-nvidia, nvidia-settings, linux-headers)?" install_closed_nvidia_dkms_driver
ask_user "Do you want to install recommended software (yay, ufw, fzf, python, python-pip, bluez, blueman, bluez-utils, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)?" install_recommended_software

echo -e "${blue}Do you use KDE or Gnome? [k/g/n]:${reset}"
read -r -n 1 desktop_env
echo ""
if [[ $desktop_env =~ ^[Kk]$ ]]; then
  ask_user "Do you want to install Dolphin?" install_dolphin
elif [[ $desktop_env =~ ^[Gg]$ ]]; then
  ask_user "Do you want to install Gnome Tweaks?" install_gnome_tweaks
fi

if $install_cachyos; then
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz &&
  tar xvf cachyos-repo.tar.xz &&
  cd cachyos-repo &&
  sudo ./cachyos-repo.sh &&
  cd .. &&
  rm -rf cachyos-repo cachyos-repo.tar.xz &&
  sudo pacman -S --noconfirm cachyos-settings
fi

if $install_chaotic; then
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
  sudo pacman-key --lsign-key 3056513887B78AEB &&
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst &&
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst &&
  grep -q 'chaotic-aur' /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf &&
  sudo pacman -Sy
fi

if $install_open_nvidia_driver; then
  sudo pacman -S --needed --noconfirm linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
fi

if $install_closed_nvidia_dkms_driver; then
  sudo pacman -S --needed --noconfirm nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings linux-headers

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
fi

exit 0
