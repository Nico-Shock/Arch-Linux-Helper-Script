# Perfect Helper Script for Post Setup After an Arch Installation

### **You can run this command to execute the script directly:**
```
bash <(curl -L https://github.com/Nico-Shock/Arch-Linux-Helper-Script/releases/latest/download/Helper.sh)
```

### *OR FOR v.1.0.3 (PRE-RELEASE):*
```
bash <(curl -L github.com/Nico-Shock/Arch-Linux-Helper-Script/releases/download/v.1.0.3/Helper.sh)
```
## **What the Script Does**

- **The script will automatically install the CachyOS repos to make your system more stable and make many things easier to install from the repo. Everything will be automated so you don’t need to edit anything.**
- **Then, the script will install the Chaotic AUR repos (for the same bad explained reason as the CachyOS repos).**
- **Next, the script will install the CachyOS Kernel Manager for you.**
- **Then, the script will install the CachyOS Gaming Meta to... game on it.**
- **Installs the CachyOS open Nvidia drivers or the closed nvidia-dkms drivers.**
- **Installs lots of recommended software (the script will show you the installed packages).**
- **Installs a better kernel for you.**
- **Deletes temporary files and cleans up your system.**
- **Automatically updates your system.**
- **Remove bloatware from your Gnome Desktop (just uninstall Gnome apps considered "bloatware"). Also uninstall Timeshift.**

### *The script asks you about every step you're running before it gets executed. Future updates will be made to improve the experience.*

**How to run the script:**

- Go into the directory of the file, for example, for Downloads: `cd Downloads/`
- Then make the file executable: `chmod +x Helper.sh`
- Then execute it: `sudo ./Helper.sh`

**Troubleshooting:**

- If you get a question about adding the "Garuda Build" key, press **no** because while system upgrade it will fail completely and you need to manually install the CachyOS repos (again).

### **Infos:**

- Make sure that the pre-release script can break things because it's still in development and, because of that, it makes the script very unstable.
- The script does not install a desktop environment for you.
- AMD driver installation is not there yet (don't want to add it yet).
