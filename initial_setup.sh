#!/bin/bash

# Update OS packages and install required packages
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install mpg123 -y

# Create backup of boot config files on /boot so we fix any non-boot issues
sudo cp /boot/cmdline.txt /boot/cmdline.bkp
sudo cp /boot/config.txt /boot/config.bkp

# Append settings to hide boot text if they don't exist
cp /boot/cmdline.txt /dev/shm/cmdline.txt
for append in vt.global_cursor_default plymouth.enable
do
  grep "$append" /dev/shm/cmdline.txt > /dev/null 2>&1 || sed -i -e "s/$/ ${append}=0/" /dev/shm/cmdline.txt
done
grep "logo.nologo" /dev/shm/cmdline.txt > /dev/null 2>&1 || sed -i -e "s/$/ logo.nologo/" /dev/shm/cmdline.txt
sed -i -e 's/tty1/tty3/' /dev/shm/cmdline.txt
sudo mv /dev/shm/cmdline.txt /boot/cmdline.txt >/dev/null 2>&1

# Add 1080P settings to config.txt 
egrep -v "hdmi_group|hdmi_mode|disable_splash|disable_overscan" /boot/config.txt > /dev/shm/config.txt
echo -e "\n#Added to set resolution to 1080p\nhdmi_group=1\nhdmi_mode=16\ndisable_splash=1\ndisable_overscan=1" >> /dev/shm/config.txt
sudo mv /dev/shm/config.txt /boot/config.txt >/dev/null 2>&1

# Hide message of the day text
touch /home/pi/.hushlogin

# Hide login text for pi user
sudo sed -i -e 's/^ExecStart.*/ExecStart=-\/sbin\/agetty --skip-login --noclear --noissue --login-options "-f pi" %I $TERM/' /etc/systemd/system/getty@tty1.service.d/autologin.conf

# Setup save directory outside roms directory, map left analog stick to directional pad, and resolution to "core provided"
sed -i -e 's/.*_analog_dpad_mode.*//' /opt/retropie/configs/all/retroarch.cfg
echo "input_player1_analog_dpad_mode = \"1\"" >> /opt/retropie/configs/all/retroarch.cfg
echo "input_player2_analog_dpad_mode = \"1\"" >> /opt/retropie/configs/all/retroarch.cfg
sed -i -e 's/.*aspect_ratio_index.*//' /opt/retropie/configs/all/retroarch.cfg
echo "aspect_ratio_index = \"22\"" >> /opt/retropie/configs/all/retroarch.cfg
sed -i -e 's/.*input_max_users.*//' /opt/retropie/configs/all/retroarch.cfg
echo "input_max_users = 2" >> /opt/retropie/configs/all/retroarch.cfg
for system in $(ls /opt/retropie/configs/|grep -v "^all")
do
sudo mkdir -p /save/$system
egrep -v "savestate_directory|savefile_directory|aspect_ratio_index" /opt/retropie/configs/$system/retroarch.cfg > /opt/retropie/configs/$system/retroarch.cfg.bkp
echo "savestate_directory = \"/save/$system\"" > /opt/retropie/configs/$system/retroarch.cfg
echo "savefile_directory = \"/save/$system\"" >> /opt/retropie/configs/$system/retroarch.cfg
echo "aspect_ratio_index = \"22\"" >> /opt/retropie/configs/$system/retroarch.cfg
cat /opt/retropie/configs/$system/retroarch.cfg.bkp >> /opt/retropie/configs/$system/retroarch.cfg
done
sudo chown -R pi:pi /save

# Setup silent MP3 to fix "whine" sound in Emulation Station
mkdir /home/pi/bgm && cd /home/pi/bgm
wget http://duramecho.com/Misc/SilentCd/Silence32min.mp3.zip
unzip Silence32min.mp3.zip && rm Silence32min.mp3.zip
echo -e "while pgrep omxplayer >/dev/null; do sleep 2; done\n(sleep 10;mpg123 -f 26000 -Z /home/pi/bgm/*.mp3 >/dev/null 2>&1) &\nemulationstation" > /opt/retropie/configs/all/autostart.sh
echo "pkill -STOP mpg123" >> /opt/retropie/configs/all/runcommand-onstart.sh
echo "pkill -CONT mpg123" >> /opt/retropie/configs/all/runcommand-onend.sh
chmod a+x /opt/retropie/configs/all/runcommand-on*

# Install and run Bezel Project
cd /home/pi/RetroPie/retropiemenu/
wget https://raw.githubusercontent.com/thebezelproject/BezelProject/master/bezelproject.sh
chmod +x bezelproject.sh && ./bezelproject.sh

# Generate custom es_systems.cfg
kill $(ps -ef|grep emulationstation|grep -v grep|tail -1|awk '{print $2}')
cd  /home/pi/RetroPie/retropiemenu/
wget https://raw.githubusercontent.com/parker-hemphill/custom_es_systems/master/generate_es_list.sh
chmod +x generate_es_list.sh && ./generate_es_list.sh

# Reboot system
sudo reboot
