#!/bin/bash

###########################################################
# Created by @tazboyz16
# This Script was created at
# https://github.com/tazboyz16/Ubuntu-Server-Auto-Install
# @ 2017 Copyright
# GNU General Public License v3.0
###########################################################

if [[ $EUID -ne 0 ]]; then
	echo "This Script must be run as root"
	exit 1
fi

#when setting up proxy its replace line is http_root = /

#Modes (Variables)
# b=backup i=install r=restore u=update U=Force Update proxy=(Reverse Proxy) port=(Change port)
mode="$1"

Programloc=/opt/Headphones
backupdir=/opt/backup/Headphones
time=$(date +"%m_%d_%y-%H_%M")

case $mode in
	(-i|"")
	apt update
	apt install python git-core -y
	adduser --disabled-password --system --home /opt/ProgramData/Headphones --gecos "Headphones Service" --group Headphones
	echo '<--- Downloading latest Headphones --->'
	cd /opt &&  git clone https://github.com/rembo10/headphones.git /opt/Headphones
	chown -R Headphones:Headphones $Programloc
	chmod -R 0777 $Programloc
	echo "Allowing Headphones to be accessed remotely"
	sudo touch /etc/default/headphones
	sudo chmod +x /opt/headphones/init-scripts/init.ubuntu
	sudo ln -s /opt/headphones/init-scripts/init.ubuntu /etc/init.d/headphones
	sudo update-rc.d headphones defaults
	sudo update-rc.d headphones enable
	sudo service headphones stop
	sed -i "s/localhost/0.0.0.0/g" $Programloc/config.ini
	echo "Creating Startup Script"
	cp /opt/install/Headphones/headphones.service /etc/systemd/system/
	chmod 644 /etc/systemd/system/headphones.service
	systemctl enable headphones.service
	systemctl restart headphones.service
	;;
	(-r)
	echo "<--- Restoring Headphones Settings --->"
	echo "Stopping Headphones"
	systemctl stop headphones
	cat /opt/install/Headphones/Headphones.txt > $Programloc/config.ini
	chown -R Headphones:Headphones $Programloc
	chmod -R 0777 $Programloc
	echo "Starting up Headphones"
	systemctl start headphones
	;;
	(-b)
	echo "Stopping Headphones"
  systemctl stop headphones
  echo "Making sure Backup Dir exists"
  mkdir -p $backupdir
  echo "Backing up Headphones to /opt/backup"
	cp $Programloc/config.ini $backupdir
	echo "Data Folder might be located under $Programloc if theres a Data Folder created"
	echo "some install dont have it"
	cp $Programloc/Data $backupdir
  tar -zcvf /opt/backup/Headphones_FullBackup-$time.tar.gz $backupdir
  echo "Restarting up Headphones"
	systemctl start headphones
	;;
	(-u)
	#Checking if Program is installed
		if [ ! -d "$Programloc" ]; then
		echo "Headphones not installed at '$Programloc'. Update Failed"
		exit 0;
		fi
	echo "Stopping Headphones to Update"
	sudo systemctl stop headphones
	sleep 5
	cd $Programloc
	git pull
	echo "Starting Headphones"
	sudo systemctl start headphones
	;;
	(-U)
	#Checking if Program is installed
		if [ ! -d "$Programloc" ]; then
		echo "Headphones not installed at '$Programloc'. Update Failed"
		exit 0;
		fi
	echo "Stopping Headphones to Force Update"
	sudo systemctl stop headphones
	sleep 5
	cd $Programloc
	git fetch --all
	git reset --hard origin/master
	git pull
	echo "Starting Headphones"
	sudo systemctl start headphones
	;;
	(-proxy)
	sudo systemctl stop headphones
	sed -i 's#.*http_root = .*#http_root = /headphones#' /opt/Headphones/config.ini
	systemctl restart apache2 headphones
	;;
	(-port)
	echo "What Port Number Would you like to change Headphones to?"
	read Port
	sudo systemctl stop headphones
	sed -i "s#http_port = .*#http_port = $Port#" /opt/Headphones/config.ini
	sed -i "s#1:.*/headphones#1:$Port/headphones#" /etc/apache2/sites-available/000-default.conf
	echo "Changed Port over to $Port"
	systemctl restart apache2 headphones
	;;
    	(-*) echo "Invalid Argument"; exit 0;;
esac
exit 0
