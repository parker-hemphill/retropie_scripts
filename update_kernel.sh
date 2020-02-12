#!/bin/bash
UPDATE_LOG=/var/tmp/retropie_update.log

updatePACKAGE(){
for action_verb in build:compile install:install configure:configuration
do
  action=$(echo $action_verb|awk -F':' '{print $1}')
  verb=$(echo $action_verb|awk -F':' '{print $2}')
  sudo __nodialog=1 /home/pi/RetroPie-Setup/retropie_packages.sh $1 $action > /dev/null 2>&1
  echo "Performing $verb for $1"
done
}

update_retropie(){
cd /home/pi/RetroPie-Setup/
REBOOT=yes
echo "Gracefully stopping Emulation Station"
kill $(ps -ef|grep '/opt/retropie/supplementary/emulationstation/emulationstation'|grep -v grep|tail -1|awk '{print $2}') > /dev/null 2>&1
echo "Checking for OS updates"
sudo apt-get -qq update
sudo apt-get -qq -y dist-upgrade
echo "[$(date +%b-%d" "%H:%M:%S)] OS update complete"|tee >> $UPDATE_LOG
#Install binary only packages
for package in runcommand retropiemenu
do
  for action_verb in install_bin:install configure:configuration
  do
    action=$(echo $action_verb|awk -F':' '{print $1}')
    verb=$(echo $action_verb|awk -F':' '{print $2}')
    echo "Performing $verb for $package"
    sudo __nodialog=1 /home/pi/RetroPie-Setup/retropie_packages.sh $package $action > /dev/null 2>&1
  done
  echo "[$(date +%b-%d" "%H:%M:%S)] $package binary updated"|tee >> $UPDATE_LOG
done
#Compile and install packages
for package in emulationstation retroarch $(ls /opt/retropie/libretrocores/)
do
  if [[ ! -d /home/pi/RetroPie-Setup/tmp/build/$package ]]
  then
    sudo mkdir /home/pi/RetroPie-Setup/tmp/build/$package
    echo "Installed version of $package unknown.  Compiling and installing latest version."
    sudo __nodialog=1 /home/pi/RetroPie-Setup/retropie_packages.sh $package sources > /dev/null 2>&1
    updatePACKAGE $package
    echo "  [$(date +%b-%d" "%H:%M:%S)] $package updated"|tee >> $UPDATE_LOG
  else
    cd /home/pi/RetroPie-Setup/tmp/build/$package
    if [[ ! $(sudo git pull|grep 'Already up to date.') ]] || [[ -f /dev/shm/$package ]]
    then
      echo "Update found for $package, cloning updated GIT repo."
      updatePACKAGE $package
      echo "  [$(date +%b-%d" "%H:%M:%S)] $package updated"|tee >> $UPDATE_LOG
    else
      echo "  [$(date +%b-%d" "%H:%M:%S)] $package already up-to-date"|tee >> $UPDATE_LOG
    fi
  fi
done
}

update_kernel(){
echo "Gracefully stopping Emulation Station"
kill $(ps -ef|grep '/opt/retropie/supplementary/emulationstation/emulationstation'|grep -v grep|tail -1|awk '{print $2}') > /dev/null 2>&1
echo "Configuring kernel source"
sudo make --silent bcm2711_defconfig
sudo sed -i -e 's/^# CONFIG_LOGO is not set/CONFIG_LOGO=n/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^CONFIG_LOGO_LINUX_CLUT224=y/CONFIG_LOGO_LINUX_CLUT224=n/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^# CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE is not set/# CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE is not set/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^CONFIG_CPU_FREQ_DEFAULT_GOV_POWERSAVE=y/CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^CONFIG_CONSOLE_LOGLEVEL_DEFAULT=7/CONFIG_CONSOLE_LOGLEVEL_DEFAULT=2/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^CONFIG_CONSOLE_LOGLEVEL_QUIET=4/CONFIG_CONSOLE_LOGLEVEL_QUIET=2/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^CONFIG_MESSAGE_LOGLEVEL_DEFAULT=4/CONFIG_MESSAGE_LOGLEVEL_DEFAULT=2/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
sudo sed -i -e 's/^CONFIG_BOOT_PRINTK_DELAY=y/CONFIG_BOOT_PRINTK_DELAY=n/' /home/pi/RetroPie-Setup/tmp/build/kernel/.config
echo "Compiling kernel"
sudo make -j4 --silent -w zImage modules dtbs
sudo make --silent -w modules_install
echo "Installing new kernel"
sudo cp arch/arm/boot/dts/*.dtb /boot/ > /dev/null 2>&1
sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/ > /dev/null 2>&1
sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/ > /dev/null 2>&1
sudo cp arch/arm/boot/zImage /boot/silent-kernel.img > /dev/null 2>&1
grep -v ^kernel= /boot/config.txt > /tmp/config.txt
echo "kernel=silent-kernel.img" >> /tmp/config.txt
sudo chown root:root /tmp/config.txt
sudo mv /tmp/config.txt /boot/config.txt
echo "[$(date +%b-%d" "%H:%M:%S)] kernel updated"|tee >> $UPDATE_LOG > /dev/null 2>&1
REBOOT=yes
}

if [[ $(ps -ef|grep /opt/retropie/emulators/retroarch/bin/retroarch|grep -v grep|wc -l) -eq 0 ]]
then
  echo "[$(date +%b-%d" "%H:%M:%S)] Update check started"|tee >> $UPDATE_LOG
  if [[ ! -d /home/pi/RetroPie-Setup/tmp/build/kernel ]]
  then
    echo "Installed version of kernel unknown.  Compiling and installing latest version."
    echo "Installing any missing packages required for kernel compile."
    sudo apt install git bc bison flex libssl-dev make -y
    sudo mkdir /home/pi/RetroPie-Setup/tmp/build/kernel > /dev/null 2>&1
    cd /home/pi/RetroPie-Setup/tmp/build/kernel
    sudo git clone --depth=1 https://github.com/raspberrypi/linux /home/pi/RetroPie-Setup/tmp/build/kernel
    update_kernel
  else
    cd /home/pi/RetroPie-Setup/tmp/build/kernel
    if [[ ! $(sudo git pull|grep 'Already up to date.') ]] || [[ -f /dev/shm/kernel ]]
    then
      echo "[$(date +%b-%d" "%H:%M:%S)] Kernel update started"|tee >> $UPDATE_LOG
      update_kernel
    else
      echo "[$(date +%b-%d" "%H:%M:%S)] Kernel already up-to-date"|tee >> $UPDATE_LOG
    fi
  fi
  cd /home/pi/RetroPie-Setup
  if [[ ! $(sudo git pull|grep 'Already up to date.') ]] || [[ -f /dev/shm/pi ]]
  then
    echo "[$(date +%b-%d" "%H:%M:%S)] RetroPie update started"|tee >> $UPDATE_LOG
    update_retropie
  else
    echo "[$(date +%b-%d" "%H:%M:%S)] RetroPie already up-to-date"|tee >> $UPDATE_LOG
  fi
else
  echo "[$(date +%b-%d" "%H:%M:%S)] System in use.  RetroPie and Kernel update skipped"|tee >> $UPDATE_LOG
fi

[[ $REBOOT == 'yes' ]] && sudo /sbin/shutdown -r -t 30
