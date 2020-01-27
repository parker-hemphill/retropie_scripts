#!/bin/bash
UPDATE_LOG=/var/tmp/retropie_update.log
CURRENT_LOG=/var/tmp/latest_update.log

update_pi(){
cd /home/pi/RetroPie-Setup/
REBOOT=yes
echo "Gracefully stopping Emulation Station"
kill $(ps -ef|grep '/opt/retropie/supplementary/emulationstation-dev/emulationstation'|grep -v grep|tail -1|awk '{print $2}') > /dev/null 2>&1
echo "[$(date +%b-%d" "%H:%M:%S)] Update started" > $CURRENT_LOG
echo "Update started $(date +%b-%d" "%H:%M)" >> $UPDATE_LOG
echo "Checking for OS updates"
sudo apt-get -qq update
sudo apt-get -qq -y dist-upgrade
echo "[$(date +%b-%d" "%H:%M:%S)] OS update check and installation complete" >> $CURRENT_LOG
#Install binary only packages
for package in runcommand retropiemenu
do
  for action in install_bin configure
  do
    sudo __nodialog=1 /home/pi/RetroPie-Setup/retropie_packages.sh $package $action > /dev/null 2>&1
    echo "Performing $action for $package"
  done
  echo "[$(date +%b-%d" "%H:%M:%S)] $package binary updated" >> $CURRENT_LOG
done
#Compile and install packages
for package in emulationstation-dev retroarch lr-beetle-ngp lr-fbneo lr-fceumm lr-gambatte lr-genesis-plus-gx lr-mame2003-plus lr-mgba lr-mupen64plus-next lr-picodrive lr-snes9x
do
  for action in sources build install configure clean
  do
    sudo __nodialog=1 /home/pi/RetroPie-Setup/retropie_packages.sh $package $action > /dev/null 2>&1
    echo "Performing $action for $package"
  done
  echo "[$(date +%b-%d" "%H:%M:%S)] $package updated" >> $CURRENT_LOG
done
}

update_kernel(){
cd /home/pi/RetroPie-Setup/tmp/linux
REBOOT=yes
echo "Gracefully stopping Emulation Station"
kill $(ps -ef|grep '/opt/retropie/supplementary/emulationstation-dev/emulationstation'|grep -v grep|tail -1|awk '{print $2}') > /dev/null 2>&1
echo "Getting latest kernel source"
echo "Configuring kernel source"
sudo make --silent bcm2711_defconfig
sudo sed -i -e 's/^CONFIG_LOGO=y/CONFIG_LOGO=n/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^CONFIG_LOGO_LINUX_CLUT224=y/CONFIG_LOGO_LINUX_CLUT224=n/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^# CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE is not set/# CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE is not set/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE=y/CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^CONFIG_CONSOLE_LOGLEVEL_DEFAULT=7/CONFIG_CONSOLE_LOGLEVEL_DEFAULT=2/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^CONFIG_CONSOLE_LOGLEVEL_QUIET=4/CONFIG_CONSOLE_LOGLEVEL_QUIET=2/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^CONFIG_MESSAGE_LOGLEVEL_DEFAULT=4/CONFIG_MESSAGE_LOGLEVEL_DEFAULT=2/' /home/pi/RetroPie-Setup/tmp/linux/.config
sudo sed -i -e 's/^CONFIG_BOOT_PRINTK_DELAY=y/CONFIG_BOOT_PRINTK_DELAY=n/' /home/pi/RetroPie-Setup/tmp/linux/.config
echo "Compiling kernel"
sudo make -j4 --silent zImage modules dtbs
sudo make --silent modules_install
echo "Installing new kernel"
sudo cp arch/arm/boot/dts/*.dtb /boot/ > /dev/null 2>&1
sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/ > /dev/null 2>&1
sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/ > /dev/null 2>&1
sudo cp arch/arm/boot/zImage /boot/silent-kernel.img > /dev/null 2>&1
echo "[$(date +%b-%d" "%H:%M:%S)] kernel updated" >> $CURRENT_LOG > /dev/null 2>&1
echo "  Update complete $(date +%b-%d" "%H:%M)" >> $UPDATE_LOG > /dev/null 2>&1
}

######################
# Script starts here #
######################

if [ $(ps -ef|grep /opt/retropie/emulators/retroarch/bin/retroarch|grep -v grep|wc -l) -eq 0 ]
then
  cd /home/pi/RetroPie-Setup/tmp/linux
  if [[ ! $(sudo git pull|grep 'Already up to date.') ]] || [[ -f /dev/shm/kernel ]]
  then
    update_kernel
  fi
#  cd /home/pi/RetroPie-Setup
#  if [[ ! $(git pull|grep 'Already up to date.') ]] || [[ -f /dev/shm/pi ]]
#  then
#    update_pi
#  fi
fi

[[ $REBOOT == 'yes' ]] && sudo /sbin/shutdown -r -t 30
