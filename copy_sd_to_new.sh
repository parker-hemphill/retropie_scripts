#!/bin/bash

# Mount old SD card
sudo mkdir /mnt/drive
sudo chown pi:pi /mnt/drive
sudo mount /dev/sda2 /mnt/drive/

# Copy RetroArch configs and overlays
sudo rsync -azP --links /mnt/drive/opt/retropie/configs/ /opt/retropie/configs/

# Copy Roms
sudo rsync -azP --links --exclude 'RetroPie-Setup' /mnt/drive/home/pi/ /home/pi/ 

# Copy any emulation station themes
sudo rsync -azP --links /mnt/drive/etc/emulationstation/themes/ /etc/emulationstation/themes/

# Reboot
sudo reboot
