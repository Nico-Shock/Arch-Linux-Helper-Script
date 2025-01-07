#!/bin/bash

red="\e[31m"
blue="\e[34m"
reset="\e[0m"

# btw the thinks i want to add is so hard fow me now i use more ChatGPT for this so maybe some wierd changes will come

trap "echo -e '${red}Script aborted.${reset}'; exit 1" SIGINT

set -e

response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

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

ask_partition_input() {
  local prompt="$1"
  local var_name="$2"
  while true; do
    echo -e "${blue}${prompt}:${reset}"
    read -r partition_input
    if [ -b "$partition_input" ]; then
      eval "$var_name=$partition_input"
      break
    else
      echo -e "${blue}DUDE, YOU MADE A FUCKING INVALID CHOICE. PLEASE TRY AGAIN.${reset}"
    fi
  done
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
install_new_kernel=false

clear
echo -e "${blue}Welcome to my Arch Linux post installation script!${reset}"

ask_user "Do you want to install the CachyOS repos?" install_cachyos
ask_user "Do you want to install the Chaotic-AUR-repos?" install_chaotic
ask_user "Do you want to install the CachyOS Kernel Manager?" install_kernel_manager
ask_user "Do you want to install the CachyOS Gaming Meta?" install_gaming_meta
ask_user "Do you want to install Nvidia open drivers?" install_open_nvidia_driver

if ! $install_open_nvidia_driver; then
  ask_user "Do you want to install Nvidia closed source drivers?" install_closed_nvidia_dkms_driver
fi

ask_user "Do you want to install a new linux kernel?" install_new_kernel

kernel_choice=0

ask_bootloader() {
  echo -e "PLEASE SELECT YOUR BOOTLOADER OPTION (only systemdboot is supported for now):"
  echo -e "1. systemdboot"
  echo -e "2. Do nothing (You will need to manually edit your bootloader configuration)"
  
  read -r -n 1 bootloader_choice
  echo ""

  case $bootloader_choice in
    1)
      echo -e "PLEASE EDIT YOUR BOOTLOADER CONFIGURATION TO BOOT FROM THE NEW INSTALLED KERNEL LATER"
      lsblk
      ask_partition_input "PLEASE CHOOSE YOUR CORRECT PARTITION (ROOT PARTITION). EXAMPLE: /DEV/NVME0N1P3" root_partition
      ask_user "ARE YOU SURE YOUR INPUT IS CORRECT? A MISTAKE WILL PREVENT YOUR SYSTEM FROM BOOTING UNLESS YOU EDIT THE BOOTLOADER CONFIG MANUALLY?" sure_partition
      if $sure_partition; then
        ask_user "SHOULD I CREATE A 'ARCH.CONF' IN '/BOOT/LOADER/ENTRIES' AND DELETE ALL OTHER BOOT ENTRIES?" create_arch_conf
        if $create_arch_conf; then
          sudo rm -r /boot/loader/entries
          sudo mkdir -p /boot/loader/entries
          case $kernel_choice in
            1) 
              echo -e "title Arch Linux\nlinux /vmlinuz-linux-cachyos\ninitrd /initramfs-linux-cachyos.img" | sudo tee /boot/loader/entries/arch.conf
              echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $root_partition) rw" | sudo tee -a /boot/loader/entries/arch.conf
              ;;
            2)
              echo -e "title Arch Linux\nlinux /vmlinuz-linux-cachyos-rc\ninitrd /initramfs-linux-cachyos-rc.img" | sudo tee /boot/loader/entries/arch.conf
              echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $root_partition) rw" | sudo tee -a /boot/loader/entries/arch.conf
              ;;
            3)
              echo -e "title Arch Linux\nlinux /vmlinuz-linux-vfio\ninitrd /initramfs-linux-vfio.img" | sudo tee /boot/loader/entries/arch.conf
              echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $root_partition) rw" | sudo tee -a /boot/loader/entries/arch.conf
              ;;
            *)
              echo -e "DUDE, YOU MADE A FUCKING INVALID CHOICE. PLEASE CHOOSE THE RIGHT KERNEL."
              exit 1
              ;;

          esac
        fi
      fi
      ;;

    2)
      echo -e "PLEASE EDIT YOUR BOOTLOADER CONFIGURATION TO BOOT FROM THE NEW INSTALLED KERNEL LATER"
      ;;

    *)
      echo -e "DUDE, YOU MADE A FUCKING INVALID CHOICE. PLEASE CHOOSE 1 OR 2."
      exit 1
      ;;

  esac
}

if $install_new_kernel; then
  echo -e "PLEASE SELECT THE NUMBER FOR THE KERNEL YOU WANT TO INSTALL:"
  echo -e "1. linux-cachyos"
  echo -e "2. linux-cachyos-rc"
  echo -e "3. linux-vfio"
  read -r -n 1 kernel_choice
  echo ""
fi

if $install_new_kernel; then
  install_kernel() {
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
        echo -e "DUDE, YOU MADE A FUCKING INVALID CHOICE. PLEASE CHOOSE 1, 2, OR 3."
        exit 1
        ;;

    esac
  }
  install_kernel
  ask_bootloader
fi

ask_user "Do you want to install recommended software? (yay, ufw, fzf, python, python-pip, bluez, blueman, bluez-utils, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)" install_recommended_software

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

if $install_cachyos; then
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz &&
  tar xvf cachyos-repo.tar.xz &&
  cd cachyos-repo &&
  sudo ./cachyos-repo.sh &&
  cd .. &&
  rm -rf cachyos-repo cachyos-repo.tar.xz &&
  sudo pacman -S --noconfirm cachyos-settings
  yay -S pacman
fi

if $install_chaotic; then
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &&
  sudo pacman-key --lsign-key 3056513887B78AEB &&
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst &&
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst &&
  grep -q 'chaotic-aur' /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf &&
  sudo pacman -Sy
fi

if $install_kernel_manager; then
  sudo pacman -S --noconfirm cachyos-kernel-manager
fi

if $install_gaming_meta; then
  sudo pacman -S --noconfirm cachyos-gaming-meta
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
  sudo systemctl enable --now ufw bluetooth preload
fi

make_system_more_stable() {
  sudo pacman -Syuu --noconfirm
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz &&
  tar xvf cachyos-repo.tar.xz &&
  cd cachyos-repo &&
  sudo ./cachyos-repo.sh &&
  cd .. &&
  rm -rf cachyos-repo cachyos-repo.tar.xz
}

make_system_more_stable

cleanup_temp_files() {
  sudo pacman -Scc --noconfirm
}

cleanup_temp_files
exit 0
