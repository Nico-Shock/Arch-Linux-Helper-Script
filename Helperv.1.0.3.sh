#!/bin/bash

red="\e[31m"
blue="\e[34m"
reset="\e[0m"

trap "echo -e '${red}Script aborted.${reset}'; exit 1" SIGINT

run_cmd() {
  while true; do
    "$@"
    if [ $? -eq 0 ]; then
      break
    else
      echo -e "${red}DUDE THE FUCKING SCRIPT MADE A FUCKING ERROR DO YOU STILL WANT TO CONTINUE? [y/n]${reset}"
      read -r -n 1 ans
      echo ""
      if [[ $ans =~ ^[Nn]$ ]]; then
        exit 1
      fi
    fi
  done
}

ask_user() {
  local prompt="$1"
  local var_name="$2"
  while true; do
    echo -e "${blue}${prompt} [y/n]:${reset}"
    read -r -n 1 response
    echo ""
    if [[ $response =~ ^[Yy]$ ]]; then
      eval "$var_name=true"
      break
    elif [[ $response =~ ^[Nn]$ ]]; then
      eval "$var_name=false"
      break
    else
      echo -e "${blue}DUDE, YOU MADE A FUCKING INVALID INPUT. PLEASE TRY AGAIN.[y/n]:${reset}"
    fi
  done
}

install_packages() {
  local packages=("$@")
  if [ ${#packages[@]} -ne 0 ]; then
    run_cmd sudo pacman -S --needed --noconfirm "${packages[@]}"
  fi
}

install_cachyos=false
install_chaotic=false
install_kernel_manager=false
install_gaming_meta=false
install_open_nvidia_driver=false
install_closed_nvidia_dkms_driver=false
install_recommended_software=false
install_bluetooth=false
install_dolphin=false
install_gnome_tweaks=false
install_new_kernel=false
patch_pacman=false
kernel_choice=""

clear
run_cmd sudo pacman -Syu --noconfirm
clear

echo -e "${blue}Welcome to my Arch Linux post installation script!${reset}"

ask_user "Do you want to install the CachyOS repos?" install_cachyos
ask_user "Do you want to install the Chaotic-AUR-repos?" install_chaotic
ask_user "Do you want to install the CachyOS Kernel Manager?" install_kernel_manager
ask_user "Do you want to install the CachyOS Gaming Meta?" install_gaming_meta
ask_user "Do you want to install Nvidia open drivers?" install_open_nvidia_driver

if ! $install_open_nvidia_driver; then
  ask_user "Do you want to install Nvidia closed dkms drivers?" install_closed_nvidia_dkms_driver
fi

ask_user "Do you want to install a new linux kernel?" install_new_kernel

if $install_new_kernel; then
  echo -e "PLEASE SELECT THE NUMBER FOR THE KERNEL YOU WANT TO INSTALL:"
  echo -e "1. linux-cachyos"
  echo -e "2. linux-cachyos-rc"
  read -r -n 1 kernel_choice
  echo ""
fi

ask_user "Do you want to install recommended software? (yay, ufw, fzf, python, python-pip, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)" install_recommended_software
ask_user "Do you want to install Bluetooth?" install_bluetooth

echo -e "${blue}Do you use KDE or Gnome? [k/g/n]:${reset}"
read -r -n 1 desktop_env
echo ""

while [[ ! "$desktop_env" =~ ^[KkGgNn]$ ]]; do
  echo -e "${blue}DUDE, YOU MADE A FUCKING INVALID INPUT. PLEASE TRY AGAIN.[k/g/n]:${reset}"
  read -r -n 1 desktop_env
  echo ""
done

if [[ $desktop_env =~ ^[Kk]$ ]]; then
  ask_user "Do you want to install Dolphin?" install_dolphin
elif [[ $desktop_env =~ ^[Gg]$ ]]; then
  ask_user "Do you want to install Gnome Tweaks?" install_gnome_tweaks
fi

ask_user "Patch Pacman (CachyOS Pacman)?" patch_pacman

if $patch_pacman; then
  run_cmd sudo pacman -S --noconfirm pacman
fi

if $install_cachyos; then
  run_cmd wget https://mirror.cachyos.org/cachyos-repo.tar.xz
  run_cmd tar xvf cachyos-repo.tar.xz
  cd cachyos-repo
  run_cmd sudo --noconfirm ./cachyos-repo.sh
  cd ..
  run_cmd rm -rf cachyos-repo cachyos-repo.tar.xz
  run_cmd sudo pacman -S --noconfirm cachyos-settings
  run_cmd sudo pacman -Sy
fi

if $install_chaotic; then
  run_cmd sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  run_cmd sudo pacman-key --lsign-key 3056513887B78AEB
  run_cmd sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
  run_cmd sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
  run_cmd bash -c "grep -q 'chaotic-aur' /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf"
  run_cmd sudo pacman -Sy --noconfirm
fi

if $install_kernel_manager; then
  run_cmd sudo pacman -S --noconfirm cachyos-kernel-manager
fi

if $install_gaming_meta; then
  run_cmd sudo pacman -S --noconfirm cachyos-gaming-meta
fi

if $install_open_nvidia_driver; then
  run_cmd sudo pacman -S --needed --noconfirm linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
fi

if $install_closed_nvidia_dkms_driver; then
  run_cmd sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
  run_cmd sudo sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
  run_cmd sudo mkdir -p /etc/pacman.d/hooks
  run_cmd bash -c 'cat > /etc/pacman.d/hooks/nvidia.hook <<EOF
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
  run_cmd sudo pacman -Sy --noconfirm
  install_packages yay ufw fzf python python-pip zram-generator fastfetch preload flatpak git wget gedit thermald
  run_cmd sudo systemctl enable --now ufw preload
fi

if $install_bluetooth; then
  install_packages bluez blueman bluez-utils
  run_cmd sudo systemctl enable --now bluetooth
fi

if $install_new_kernel; then
  case $kernel_choice in
    1)
      run_cmd sudo pacman -Rns --noconfirm linux linux-headers 2>/dev/null || true
      run_cmd sudo pacman -S --noconfirm linux-cachyos linux-cachyos-headers
      ;;
    2)
      run_cmd sudo pacman -Rns --noconfirm linux linux-headers 2>/dev/null || true
      run_cmd sudo pacman -S --noconfirm linux-cachyos-rc linux-cachyos-rc-headers
      ;;
    *)
      echo -e "DUDE, YOU MADE A FUCKING INVALID CHOICE. PLEASE CHOOSE 1 OR 2."
      exit 1
      ;;
  esac
fi

run_cmd wget https://mirror.cachyos.org/cachyos-repo.tar.xz
run_cmd tar xvf cachyos-repo.tar.xz
cd cachyos-repo
run_cmd sudo --noconfirm ./cachyos-repo.sh
cd ..
run_cmd rm -rf cachyos-repo cachyos-repo.tar.xz

cleanup_temp_files() {
  run_cmd sudo pacman -Scc --noconfirm
  run_cmd sudo rm -rf /tmp/*
}

cleanup_temp_files
exit 0
