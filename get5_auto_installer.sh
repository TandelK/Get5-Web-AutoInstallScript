#!/bin/bash
# Project: Get5 Web API Auto Installer
# Author: TandelK
# Credits : Splewis , PhlexPlexico 
# Purpose: Get5 Web API Panel installation script

version="0.50"
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[32m This script must be run as root as it require packages to be downloaded \e[39m" 
   exit 1
fi


##Get5 WSGI Create Function
function wsgi_create(){
		if [ -f "/var/www/get5-web/get5.wsgi" ]
		then
		echo "Get5.wsgi already exist"
		break;
		else
		cd /var/www/get5-web
		echo "Creating WSGI Config File"

		echo "#!/usr/bin/python"  >> get5.wsgi
		echo "activate_this = '/var/www/get5-web/venv/bin/activate_this.py'" >> get5.wsgi
		echo 	"execfile(activate_this, dict(__file__=activate_this))" >> get5.wsgi
		echo 	"">> get5.wsgi
		echo 	"import sys">> get5.wsgi
		echo 	"import logging">> get5.wsgi
		echo 	"logging.basicConfig(stream=sys.stderr)">> get5.wsgi
		echo 	"">> get5.wsgi
		echo 	'folder = "/var/www/get5-web"'>> get5.wsgi
		echo 	"if not folder in sys.path:">> get5.wsgi
		echo 	"sys.path.insert(0, folder)">> get5.wsgi
		echo 	"sys.path.insert(0,"")">> get5.wsgi
		echo 	"">> get5.wsgi
		echo 	"from get5 import app as application">> get5.wsgi
		echo 	"import get5">> get5.wsgi
		echo 	"get5.register_blueprints()" >> get5.wsgi
		chmod +x get5.wsgi
		fi
		}

echo -e "\e[32m  Welcome to Get5 Web Panel Auto Installation script \e[39m"
PS3="Select the option >"

select option in install update 'Create WSGI' exit
do
case $option in
	install)
	if [ -d "/var/www/get5-web" ] 
			then
			echo "Installation already done and exist inside /var/www/get5-web"
		else
		
		echo -e "\e[32m Downloading Dependencies \e[39m"
		
		sudo apt-get update && apt-get upgrade -y
		
		sudo apt-get install build-essential software-properties-common -y

		sudo apt-get install python-dev python-pip apache2 libapache2-mod-wsgi -y
		
		sudo apt-get install virtualenv libmysqlclient-dev -y

		#Checking Git Package available or not
		echo -e "\e[32mChecking Git Command Status \e[39m"
		gitavailable='git'
		if ! dpkg -s $gitavailable >/dev/null 2>&1; then
			echo -e"\e[32mInstalling Git"
			sudo apt-get install $gitavailable 
		else echo -e "\e[32m Git Already Installed \e[39m"
		fi

		#Checking MySQL Server installed or not
		echo -e "\e[32mChecking MySQL Server Status \e[39m"
		sqlavailable='mysql-server'
		if ! dpkg -s $sqlavailable >/dev/null 2>&1; then
			echo -e"\e[32mInstalling MySQL Server"
			sudo apt-get install $sqlavailable 
			service mysql start
		else echo -e "\e[32m MySQL already Installed \e[39m"
		fi

		#MYSQL Information
			echo -e " \e[32m MySQL Server Database Creation \e[39m"
			echo "Enter Root Password"
			read -s sqlrootpswd
			echo -e "Enter your Username"
			read sqluser
			echo -e "Enter Password | Please remember this for future reference"
			read -s sqlpass
			echo -e "Enter Database name"
			read sqldb
			echo "Creating User"
			mysql -uroot -p$sqlrootpswd -e "CREATE USER ${sqluser}@localhost IDENTIFIED BY '${sqlpass}';"
			echo "Creating Database"
			mysql -uroot -p$sqlrootpswd -e "CREATE DATABASE ${sqldb} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
			echo "Database Created Successfully"
			echo "Granting Privileges now"
			mysql -uroot -p$sqlrootpswd -e "GRANT ALL PRIVILEGES ON ${sqldb}.* TO '${sqluser}'@'localhost' WITH GRANT OPTION;FLUSH PRIVILEGES;"
			#Only enable this from script if you want to check if database and grant permissions are working or not , just remove '#' from below 4 lines
			#echo "Checking Database Information"
			#mysql -uroot -p${sqlrootpswd} -e "SELECT USER,HOST FROM mysql.user;"
			#mysql -uroot -p${sqlrootpswd} -e "show databases;"
			#mysql -uroot -p${sqlrootpswd} -e "SHOW GRANTS FOR '${sqluser}'@'localhost';"

		echo -e "\e[32mDownloading Get5 Web Panel \e[39m"

		cd /var/www/
		# Branch Selection
		echo -e "\e[34m Github Branch Selection \e[39m"
		PS3="Select the branch to clone >"
		select branch in master development
		do
		case $branch in
		master)
			echo -e "\e[34m Downloading Master branch \e[39m"
			git clone https://github.com/PhlexPlexico/get5-web
			echo -e "\e[34m Finish Downloading Master Branch \e[39m"
			break;
		;;
		development)
			echo -e "\e[34m Downloading Development branch \e[39m"
			git clone -b development --single-branch https://github.com/PhlexPlexico/get5-web 
			echo -e "\e[34m Finish Downloading Development Branch \e[39m"
			break;
		;;
		*) 
			echo -e "\e[31mYou didnt select correct Option, Please use selection from above \e[39m"
		;;
		esac
		done	
		echo -e "\e[34mDownloaded in /var/www/get5-web \e[39m"
	
		cd /var/www/get5-web
		echo "Start Creating Virtual Environment and Download Requirements"

		virtualenv venv
		source venv/bin/activate
		pip install -r requirements.txt

		echo "Changing File permissions for required folder"
		cd /var/www/get5-web/
		chown -R www-data:www-data logs
		chown -R www-data:www-data get5/static/resource/csgo/resource/flash/econ/tournaments/teams
		chown -R www-data:www-data get5/static/resource/csgo/materials/panaroma/tournaments/teams
	
		echo "Copy Instance File"
		cd /var/www/get5-web/instance
		cp prod_config.py.default prod_config.py
		echo -e "Modify settings properly in prod_config.py"
		
		wsgi_create
	break;
	#fi
	;;
	update)
		if [ -d "/var/www/get5-web" ] 
			then
			cd /var/www/get5-web
			echo "Downloading Update" 
			git pull
			echo "Doing Requirement Update"
			source venv/bin/activate
			pip install -r requirements.txt
			echo "Doing manager upgrade command"
			./manager.py db upgrade
			sudo service apache2 restart
			echo "Update completed. Please do a refresh on webpanel for changes"
			exit 1
			else
			echo "Installation Not Found.Please use install option"
			fi
		;;
	'Create WSGI')
		if [ -f "/var/www/get5-web/get5.wsgi" ]
		then
		echo "Get5.wsgi already exist"
		else
		if [ -d "/var/www/get5-web" ]
		then
		echo "Creating new WSGI File in /var/www/get5-web/get5.wsgi"
		wsgi_create
		else
		echo "Please install the get5-web first"
		fi
		fi		
	;;
	exit)
		echo -e "\e[31m Exiting Script \e[39m"
		exit 1
	;;
	*) 		
	echo -e "\e[31m You didnt select correct Option, Please use selection from above \e[39m"
	;;
	esac
	done
function apacheconfig() 
	{
	echo "Please Enter WebSite Address with no http or https protocol" 
	read sitename
	echo "You have entered $sitename"
	while [[ $sitename == *"http"* || $sitename == *"https"* ]];
	do
		echo "Please re-enter Website Address without http or https"
		read sitename
		echo "You have enter %sitename"
	done
	echo "Enter Admin Email address"
	read adminemail
	
	select protocoltype in http https
	do
	case $protocoltype in
		http)
			echo "<VirtualHost *:80>" >>$sitename.cnf
			echo "ServerName $sitename" >>$sitename.cnf
			echo "ServerAdmin $adminemail" >>$sitename.cnf
			echo "WSGIScriptAlias / /var/www/get5-web/get5.wsgi" >>$sitename.cnf
			echo "" >>$sitename.cnf
			echo "<Directory /var/www/get5>" >>$sitename.cnf
			echo "	Order deny,allow" >>$sitename.cnf
			echo "	Allow from all" >>$sitename.cnf
			echo "	</Directory>" >>$sitename.cnf
			echo "">>$sitename.cnf
			echo "Alias /static /var/www/get5-web/get5/static" >>$sitename.cnf
			echo "<Directory /var/www/get5-web/get5/static>" >>$sitename.cnf
			echo "	Order allow,deny" >>$sitename.cnf
			echo "	Allow from all" >>$sitename.cnf
			echo "</Directory>" >>$sitename.cnf
			echo "" >>$sitename.cnf
			echo "ErrorLog ${APACHE_LOG_DIR}/error.log" >>$sitename.cnf
			echo "LogLevel warn" >>$sitename.cnf
			echo "CustomLog ${APACHE_LOG_DIR}/access.log combined" >>$sitename.cnf
			echo "</VirtualHost>" >>$sitename.cnf
			break;
			;;
		https)
			echo "<VirtualHost *:443>" >>$sitename.cnf
			echo "ServerName $sitename" >>$sitename.cnf
			echo "ServerAdmin $adminemail" >>$sitename.cnf
			echo "WSGIScriptAlias / /var/www/get5-web/get5.wsgi" >>$sitename.cnf
			echo "" >>$sitename.cnf
			echo "<Directory /var/www/get5>" >>$sitename.cnf
			echo "	Order deny,allow" >>$sitename.cnf
			echo "	Allow from all" >>$sitename.cnf
			echo "	</Directory>" >>$sitename.cnf
			echo "">>$sitename.cnf
			echo "Alias /static /var/www/get5-web/get5/static" >>$sitename.cnf
			echo "<Directory /var/www/get5-web/get5/static>" >>$sitename.cnf
			echo "	Order allow,deny" >>$sitename.cnf
			echo "	Allow from all" >>$sitename.cnf
			echo "</Directory>" >>$sitename.cnf
			echo "" >>$sitename.cnf
			echo "	ErrorLog ${APACHE_LOG_DIR}/error.log" >>$sitename.cnf
			echo "LogLevel warn" >>$sitename.cnf
			echo "CustomLog ${APACHE_LOG_DIR}/access.log combined" >>$sitename.cnf
			echo "</VirtualHost>" >>$sitename.cnf
			break;
			;;
		esac
		done
	}