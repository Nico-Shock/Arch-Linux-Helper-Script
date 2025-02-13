#!/bin/bash
set -eo pipefail
red="\e[31m"
blue="\e[34m"
reset="\e[0m"

trap "echo -e '${red}Script aborted.${reset}'; exit 1" SIGINT

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
install_bluetooth=false
install_new_kernel=false
install_cachyos_pacman=false
depload_gnome=false
kernel_choice=""
change_parallels=false

clear

sudo pacman -Syu --noconfirm

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
  while true; do
    echo -e "PLEASE SELECT THE NUMBER FOR THE KERNEL YOU WANT TO INSTALL (your choice will uninstall the other option):"
    echo -e "1. linux-cachyos"
    echo -e "2. linux-cachyos-rc"
    read -r -n 1 kernel_choice
    echo ""
    if [[ "$kernel_choice" == "1" || "$kernel_choice" == "2" ]]; then
      break
    else
      echo -e "${blue}DUDE, YOU MADE A FUCKING INVALID INPUT. PLEASE TRY AGAIN (choose 1 or 2):${reset}"
    fi
  done
fi

ask_user "Do you want to install recommended software? (yay, ufw, fzf, python, python-pip, zram-generator, fastfetch, preload, flatpak, git, wget, gedit, thermald)" install_recommended_software

ask_user "Do you want to install Bluetooth?" install_bluetooth

echo -e "${blue}Do you use KDE, Gnome or none? [k/g/n]:${reset}"
read -r -n 1 desktop_env
echo ""
while [[ ! "$desktop_env" =~ ^[KkGgNn]$ ]]; do
  echo -e "${blue}DUDE, YOU MADE A FUCKING INVALID INPUT. PLEASE TRY AGAIN.[k/g/n]:${reset}"
  read -r -n 1 desktop_env
  echo ""
done

ask_user "Install CachyOS Pacman (CachyOS Pacman)?" install_cachyos_pacman

if [[ "$desktop_env" =~ ^[Gg]$ ]]; then
  ask_user "Depload your Gnome desktop (if bloatware exists)?" depload_gnome
fi

ask_user "Do you want to change parallels downloads (make downloads faster)?" change_parallels

if $change_parallels; then
  while true; do
    echo -e "${blue}PLEASE CHOOSE AN OPTION (max. 20, min. 5):${reset}"
    read -r parallel_input
    if [[ "$parallel_input" =~ ^[0-9]+$ ]] && [ "$parallel_input" -ge 5 ] && [ "$parallel_input" -le 20 ]; then
      break
    else
      echo -e "${blue}DUDE, YOU MADE A FUCKING INVALID INPUT. PLEASE TRY AGAIN (choose a number between 5 and 20):${reset}"
    fi
  done
  if grep -q "^#\?ParallelDownloads" /etc/pacman.conf; then
    sudo sed -i -E "s/^\s*#?\s*(ParallelDownloads\s*=\s*)[0-9]+/\1$parallel_input/" /etc/pacman.conf
  else
    echo -e "\nParallelDownloads = $parallel_input" | sudo tee -a /etc/pacman.conf
  fi
fi

echo ""

if $install_cachyos; then
  rm -rf cachyos-repo
  sudo pacman -S --needed --noconfirm wget
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz
  tar xvf cachyos-repo.tar.xz
  cd cachyos-repo
  sudo ./cachyos-repo.sh
  cd ..
  rm -rf cachyos-repo cachyos-repo.tar.xz
  sudo pacman -S --needed --noconfirm cachyos-settings
  echo ""
fi

if $install_chaotic; then
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
  sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
  grep -q 'chaotic-aur' /etc/pacman.conf || echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
  sudo pacman -Sy --noconfirm
  echo ""
fi

if $install_kernel_manager; then
  sudo pacman -S --needed --noconfirm cachyos-kernel-manager
  echo ""
fi

if $install_gaming_meta; then
  sudo pacman -S --needed --noconfirm cachyos-gaming-meta
  echo ""
fi

if $install_open_nvidia_driver; then
  sudo pacman -S --needed --noconfirm linux-cachyos-nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
  echo ""
fi

if $install_closed_nvidia_dkms_driver; then
  sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-nvidia-utils lib32-opencl-nvidia nvidia-settings
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
  echo ""
fi

if $install_new_kernel; then
  case $kernel_choice in
    1)
      sudo pacman -Rns --noconfirm linux linux-headers 2>/dev/null || true
      sudo pacman -S --needed --noconfirm linux-cachyos linux-cachyos-headers
      ;;
    2)
      sudo pacman -Rns --noconfirm linux linux-headers 2>/dev/null || true
      sudo pacman -S --needed --noconfirm linux-cachyos-rc linux-cachyos-rc-headers
      ;;
    *)
      echo -e "DUDE, YOU MADE A FUCKING INVALID INPUT. PLEASE CHOOSE 1 OR 2."
      exit 1
      ;;
  esac
  echo ""
fi

if $install_recommended_software; then
  install_packages yay ufw fzf python python-pip zram-generator fastfetch preload flatpak git wget gedit thermald
  sudo systemctl enable --now ufw preload
  echo ""
fi

if $install_bluetooth; then
  install_packages bluez blueman bluez-utils
  if ! systemctl is-active --quiet bluetooth; then
    sudo systemctl enable --now bluetooth
  fi
  echo ""
fi

if [[ "$desktop_env" =~ ^[Kk]$ ]]; then
  sudo pacman -S --needed --noconfirm dolphin
elif [[ "$desktop_env" =~ ^[Gg]$ ]]; then
  sudo pacman -S --needed --noconfirm gnome-tweaks
fi
echo ""

if $install_cachyos_pacman; then
  sudo pacman -S --needed --noconfirm pacman
  echo ""
fi

if [[ "$desktop_env" =~ ^[Gg]$ ]] && $depload_gnome; then
  sudo pacman -Rnns --noconfirm $(pacman -Qq | grep -i '^gnome' | grep -v -E '^(gnome-shell|gnome-terminal|gnome-control-center|gnome-software|gnome-menus|gnome-shell-extensions|gnome-system-monitor|mutter|gdm|eog|totem|gnome-desktop|gnome-app-list|gnome-autoar|gnome-desktop-common|gnome-settings-daemon|gnome-online-accounts|gnome-color-manager|gnome-bluetooth|gnome-session)$')
  echo ""
fi

if $install_cachyos; then
  rm -rf cachyos-repo
  wget https://mirror.cachyos.org/cachyos-repo.tar.xz
  tar xvf cachyos-repo.tar.xz
  cd cachyos-repo
  sudo ./cachyos-repo.sh
  cd ..
  rm -rf cachyos-repo cachyos-repo.tar.xz
  echo ""
fi

exit 0
