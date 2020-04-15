#!/bin/bash

#Set your github username, email,  and password
github_user='USERNAME'
github_email='GITHUB_EMAIL_ACCOUNT'
github_password='GITHUB_PASSWORD'

#Setup initial github repo and symlink configs to original location
if [[ ! -f /home/pi/.config/.retropie_github ]]
then
  #Create directory to hold configs
  mkdir /home/pi/.github_backup && cd /home/pi/.github_backup

  #Create new private repo to hold configs
  curl -u "${github_user}:${github_password}" https://api.github.com/user/repos -d '{"name":"retroarch_configs", "private":"true"}'

  #Loop to move configs to github repo and symlink to original location
  for directory in /opt/retropie/configs/*
  do
    if [[ -f $directory/retroarch.cfg ]]
    then
      mkdir -p /home/pi/.github_backup/$directory
      mv $directory/retroarch.cfg /home/pi/.github_backup/$directory
      ln -s /home/pi/.github_backup/$directory $directory/retroarch.cfg 
    fi
  done
#Create a blank, empty file so this if statement doesn't run again and initialize local repo
touch /home/pi/.config/.retropie_github
git init
git config user.email "${github_email}"
git config user.name "${github_user}"
git remote add origin https://${github_user}:${github_password}@github.com/${github_user}/retroarch_configs.git
fi

#Push local repo to github with time as the commit message
cd /home/pi/.github_backup
git add opt
git commit -m "$(date +%b-%d-%Y_%H:%M)"
git push -u origin master
