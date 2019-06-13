#!/bin/bash
# Project: Get5 Web API Auto Installer for PhlexPlexico Get5-Web
# Author: TandelK
# Credits : Splewis , PhlexPlexico 
# Purpose: Get5 Web API Panel installation script
# Website : 
version="0.55"
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[32m This script must be run as root as it require packages to be downloaded \e[39m" 
   exit 1
fi


##Get5 WSGI Create Function
	function wsgi_create()
	{
	if [ -f "/var/www/get5-web/get5.wsgi" ]
	then
		echo "Get5.wsgi already exist"
		break;
	else
		if [! -d "/var/www/get5-web"]
		then
			echo "Get5 Web Installation not detected , Please install Get5-Web first"
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
	fi
	}
	
#Apache Config
		function apacheconfig() 
		{
			cd /etc/apache2/sites-enabled/
			echo "Please Enter Panel Address without http or https protocol" 
			read sitename
			echo "You have entered $sitename"
			while [[ $sitename == *"http"* || $sitename == *"https"* ]];
				do
					echo "Please re-enter Website Address without http or https"
					read -r sitename
					echo "You have entered $sitename"
				done
			echo "Enter Admin Email address: "; 
			read adminemail
				if [[ -f /etc/apache2/sites-enabled/$sitename.conf && -f /etc/apache2/sites-enabled/$sitename-ssl.conf ]];
				then
					echo "Sitename Apache Config already exist in sites-enabled"
					echo "Request you to please manually update them or Delete the Existing Files"
				else
				PS3="Please Select Website Protocol Type >"
				select protocoltype in http https
					do
					case $protocoltype in
					http)
							echo "<VirtualHost *:80>" >>$sitename.conf
							echo "ServerName $sitename" >>$sitename.conf
							echo "ServerAdmin $adminemail" >>$sitename.conf
							echo "WSGIScriptAlias / /var/www/get5-web/get5.wsgi" >>$sitename.conf
							echo "" >>$sitename.conf
							echo "<Directory /var/www/get5>" >>$sitename.conf
							echo "	Order deny,allow" >>$sitename.conf
							echo "	Allow from all" >>$sitename.conf
							echo "	</Directory>" >>$sitename.conf
							echo "">>$sitename.conf
							echo "Alias /static /var/www/get5-web/get5/static" >>$sitename.conf
							echo "<Directory /var/www/get5-web/get5/static>" >>$sitename.conf
							echo "	Order allow,deny" >>$sitename.conf
							echo "	Allow from all" >>$sitename.conf
							echo "</Directory>" >>$sitename.conf
							echo "" >>$sitename.conf
							echo "ErrorLog ${APACHE_LOG_DIR}/error.log" >>$sitename.conf
							echo "LogLevel warn" >>$sitename.conf
							echo "CustomLog ${APACHE_LOG_DIR}/access.log combined" >>$sitename.conf
							echo "</VirtualHost>" >>$sitename.conf
						break;
					;;
					https)
						echo "Enabling SSL Support"
						a2enmod ssl
						##SSL Certificate
						echo "Please provide your SSL Certificate Path"
						read crtpath
						echo "You have entered $crtpath"
						while [ ! -f "$crtpath" ];
						do 
							echo "File not found , Please re-enter Certificate Path"
							read crtpath
							echo "You have entered $crtpath"
						done
						while [[ ${crtpath##*.} != 'crt' ]];
						do 
							echo "The file entered does not have .crt extension, Please give the path again"
							read crtpath
							echo "You have entered now $crtpath"
						done
						echo "Please provide your SSL Prviate Key Path"
						##SSL Key
						read crtkey
						while [ ! -f "$crtkey" ];
						do 
							echo "File not found , Please re-enter Private Key Path"
							read crtkey
							echo "You have entered $crtkey"
						done
						while [[ ${crtkey##*.} != 'key' ]];
						do 
							echo "The file entered does not have .key extension, Please give the path again"
							read crtkey
							echo "You have entered now $crtkey"
						done
						echo "<IfModule mod_ssl.c>">>$sitename-ssl.conf
						echo "<VirtualHost *:443>" >>$sitename-ssl.conf
						echo "ServerName $sitename" >>$sitename-ssl.conf
						echo "ServerAdmin $adminemail" >>$sitename-ssl.conf
						echo "WSGIScriptAlias / /var/www/get5-web/get5.wsgi" >>$sitename-ssl.conf
						echo "" >>$sitename-ssl.conf
						echo "<Directory /var/www/get5>" >>$sitename-ssl.conf
						echo "	Order deny,allow" >>$sitename-ssl.conf
						echo "	Allow from all" >>$sitename-ssl.conf
						echo "	</Directory>" >>$sitename-ssl.conf
						echo "">>$sitename-ssl.conf
						echo "Alias /static /var/www/get5-web/get5/static" >>$sitename-ssl.conf
						echo "<Directory /var/www/get5-web/get5/static>" >>$sitename-ssl.conf
						echo "	Order allow,deny" >>$sitename-ssl.conf
						echo "	Allow from all" >>$sitename-ssl.conf
						echo "</Directory>" >>$sitename-ssl.conf
						echo "" >>$sitename-ssl.conf
						echo "ErrorLog ${APACHE_LOG_DIR}/error.log" >>$sitename-ssl.conf
						echo "LogLevel warn" >>$sitename-ssl.conf
						echo "CustomLog ${APACHE_LOG_DIR}/access.log combined" >>$sitename-ssl.conf
						echo "">>$sitename-ssl.conf
						echo "SSLEngine on">>$sitename-ssl.conf
						echo "SSLCertificateFile $crtpath">>$sitename-ssl.conf
						echo "SSLCertificateKeyFile $crtkey">>$sitename-ssl.conf
						echo "">>$sitename-ssl.conf
						echo '<FilesMatch "\.(cgi|shtml|phtml|php)$">'>>$sitename-ssl.conf
						echo "SSLOptions +StdEnvVars">>$sitename-ssl.conf
						echo "</FilesMatch>">>$sitename-ssl.conf
						echo "<Directory /usr/lib/cgi-bin>">>$sitename-ssl.conf
						echo "SSLOptions +StdEnvVars">>$sitename-ssl.conf
						echo "</Directory>">>$sitename-ssl.conf
						echo "</VirtualHost>" >>$sitename-ssl.conf
						echo "</IfModule>">>$sitename-ssl.conf
						
						if [ -f /etc/apache2/sites-enabled/$sitename.conf]
							then
								echo "File Already Exist of http Redirect"
							else
								echo "<VirtualHost *:80>" >>$sitename.conf
								echo "ServerName $sitename" >>$sitename.conf
								echo "Redirect Permanent / https://$sitename" >>$sitename.conf
								echo "</VirtualHost>" >>$sitename.conf
						fi
						break;
					;;
					*) 		
						echo -e "\e[31m You didnt select correct Option, Please use selection from above \e[39m"
					;;
					esac
					done
					fi
					echo "Restarting Apache2 Service"
					service apache2 restart
					break;
		}

##Web Installation
echo -e "\e[32m  Welcome to Get5 Web Panel Auto Installation script \e[39m"
PS3="Select the option >"

select option in Install Update 'Create WSGI' 'Create Apache Config' exit
do
case $option in
	Install)
		if [ -d "/var/www/get5-web" ] 
		then
			echo "Installation already done and exist inside /var/www/get5-web ."
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
				else echo -e "\e[32m MySQL Server already Installed \e[39m"
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
			chown -R www-data:www-data get5/static/resource/csgo
	
			echo "Copy Instance File"
			cd /var/www/get5-web/instance
			cp prod_config.py.default prod_config.py
			echo -e "Modify settings properly in prod_config.py"
		
			echo "Creating Get5.wsgi"
			wsgi_create
			
			echo "Creating Apache Config"
			apacheconfig

			echo "Changing Directory back to /var/www/get5-web"
			cd /var/www/get5-web
			break;
		fi
	;;
	Update)
		if [ -d "/var/www/get5-web" ] 
			then
			cd /var/www/get5-web
			echo "Downloading Update" 
			git pull
			echo "Doing Requirement Update"
			source venv/bin/activate
			pip install -r requirements.txt
			echo "Doing manager upgrade command"
			if [ -f /var/www/get5-web/instance/prod_config.py]
			then 
				./manager.py db upgrade
			else
				echo "You seems to not have added prod_config.py file"
			fi
			echo "Restarting Apache2 Service"
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
	'Create Apache Config')
		if [ -d "/var/www/get5-web" ]
		then
		apacheconfig
		else
		echo "You dont seem to have Get5-Web Installed"
		fi
	;;
	*) 		
	echo -e "\e[31m You didnt select correct Option, Please use selection from above \e[39m"
	;;
	esac
	done