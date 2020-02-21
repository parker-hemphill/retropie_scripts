mkdir /home/pi/RetroPie/roms/SaveDir
cd /opt/retropie/configs/all
egrep -v "savestate_directory|savefile_directory" retroarch.cfg > retroarch.bkp

echo "savestate_directory = \"/home/pi/RetroPie/roms/SaveDir\"" > /opt/retropie/configs/all/retroarch.cfg
echo "savefile_directory = \"/home/pi/RetroPie/roms/SaveDir\"" >> /opt/retropie/configs/all/retroarch.cfg
cat retroarch.bkp >> retroarch.cfg

cd /opt/retropie/configs/
for system in $(ls /opt/retropie/configs/|grep -v "^all")
do
egrep -v "savestate_directory|savefile_directory" $system/retroarch.cfg > $system/retroarch.bkp
mv /opt/retropie/configs/$system/retroarch.bkp /opt/retropie/configs/$system/retroarch.cfg
done
