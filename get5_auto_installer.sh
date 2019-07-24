#!/bin/bash
# Project: Get5 Web API Auto Installer for PhlexPlexico Get5-Web
# Author: TandelK
# Credits : Splewis , PhlexPlexico 
# Purpose: Get5 Web API Panel installation script
# Website : 
version="0.75"

# Fix for Bash Script via Wget getting skipped in starting
read -n1 -r -p "Press any key to continue..."


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
				if [[ -f /etc/apache2/sites-enabled/$sitename.conf || -f /etc/apache2/sites-enabled/$sitename-ssl.conf ]];
				then
					echo "Sitename Apache Config already exist in sites-enabled"
					echo "Request you to please manually update them or Delete the Existing Files"
					echo "File location is at /etc/apache2/sites-enabled/$sitename.conf and for HTTPS it is at /etc/apache2/sites-enabled/$sitename-ssl.conf"
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
						while [[ ! -f "$crtpath" || ${crtpath##*.} != 'crt' ]];
						do 
							echo "Please check if the file exists and it also contains .crt extension"
							read crtpath
							echo "You have entered $crtpath"
						done
						echo "Please provide your SSL Prviate Key Path"
						##SSL Key
						read crtkey
						while [[ ! -f "$crtkey"  || ${crtkey##*.} != 'key' ]];
						do 
							echo "Please check the file exists and it also contains .key extension"
							read crtkey
							echo "You have entered $crtkey"
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
								break;
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
			echo "Restarting MySQL Service"
			#This is due to any systems have any kind of MySQL Errors can be restarted with this.
			service mysql restart
			
			#MYSQL Information
			echo -e " \e[32m MySQL Server Database Creation \e[39m"
			SQLPASSWORDGET5="$(openssl rand -base64 12)"
			if [ -f /root/.my.cnf ]; then
				mysql -e "CREATE DATABASE get5 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
				mysql -e "CREATE USER get5@localhost IDENTIFIED BY '$SQLPASSWORDGET5';"
				mysql -e "GRANT ALL PRIVILEGES ON get5.* TO 'get5'@'localhost' WITH GRANT OPTION;"
				mysql -e "FLUSH PRIVILEGES;"
			# If /root/.my.cnf doesn't exist then it'll ask for root password   
			else
				echo "Please enter root user MySQL password!"
				read -p "YOUR SQL ROOT PASSWORD: " -e -i $rootpasswd rootpasswd
				until mysql -u root -p$rootpassword  -e ";" ; do
					read -p "Can't connect, please retry: " -e -i $rootpasswd rootpasswd
				done
				mysql -u root -p$rootpasswd -e "CREATE DATABASE get5 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
				mysql -u root -p$rootpasswd -e "CREATE USER get5@localhost IDENTIFIED BY '$SQLPASSWORDGET5';"
				mysql -u root -p$rootpasswd -e "GRANT ALL PRIVILEGES ON get5.* TO 'get5'@'localhost' WITH GRANT OPTION;"
				mysql -u root -p$rootpasswd -e "FLUSH PRIVILEGES;"
			fi
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
	
				#Prod Config File Creation and settings
				#Steam API Key
				echo "Enter your Steam API Key"
				read steamapi
				while [[ $steamapi == "" ]];
				do
					echo "You did not enter anything. Please re-enter Steam API Key"
					read steamapi
				done
			echo "Your Steam API Key is $steamapi"

			#Random Secret Key for Flask Cookies
			echo "Enter Random Secret Key for Flask Cookies"
			read secretkey
			while [[ $secretkey == "" ]];
				do
				echo "You did not enter anything. Please re-enter Steam API Key"
				read secretkey
			done

			#Database Key for Encryption of User Password as well as RCON Passwords of servers.
			dbkey=$(openssl rand -base64 12)

			echo "Your DB Key is $dbkey. This will encrypt user passwords in database."

			echo "##### You must change these before running
				SQLALCHEMY_DATABASE_URI = 'mysql://get5:$SQLPASSWORDGET5@localhost/get5'  # Sqlalchemy database connection info
				STEAM_API_KEY = '$steamapi'  # See https://steamcommunity.com/dev/apikey
				SECRET_KEY = '$secretkey'  # Secret key used for flask cookies
				DATABASE_KEY = '$dbkey'  # Used for encryption on database. MUST BE 16 BYTES.
				WEBPANEL_NAME = 'Get5' # Used for the title header on the webpage.
				
				##### Everything below this line is optional to change
				
				import os
				
				location = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__), '..', 'logs'))
				LOG_PATH = os.path.join(location, 'get5.log')

				DEBUG = False
				TESTING = False
				
				SQLALCHEMY_TRACK_MODIFICATIONS = False
				USER_MAX_SERVERS = 10  # Max servers a user can create
				USER_MAX_TEAMS = 100  # Max teams a user can create
				USER_MAX_MATCHES = 1000  # Max matches a user can create
				USER_MAX_SEASONS = 100 # Max seasons a user can create
				DEFAULT_PAGE = '/matches'
				ADMINS_ACCESS_ALL_MATCHES = False  # Whether admins can always access any match admin panel
				CREATE_MATCH_TITLE_TEXT = False # Whether settings for 'match title text' and 'team text' appear on 'create a match page'
				
				# All maps that are selectable in the 'create a match' page
				MAPLIST = [
					'de_dust2',
					'de_inferno',
					'de_mirage',
					'de_nuke',
					'de_overpass',
					'de_train',
					'de_vertigo',
					'de_season',
					'de_cbble',
					'de_cache',
				]
				
				# Maps whose checkbox is selected (in the mappool) by default in the 'create a match' page
				DEFAULT_MAPLIST = [
					'de_dust2',
					'de_inferno',
					'de_mirage',
					'de_nuke',
					'de_overpass',
					'de_train',
					'de_vertigo',
				]

				# You may set the server to allow allow whitelisted steamids to login.
				# By default any user can login and create teams/servers/matches.
				WHITELISTED_IDS = []
				
				# Admins will have extra access to create 'public' teams, and if ADMINS_ACCESS_ALL_MATCHES
				# is set, they can access admin info for all matches (can pause, cancel, etc.) ANY match.
				ADMIN_IDS = []" >> /var/www/get5-web/instance/prod_config.py
			
			echo "File is created under /var/www/get5-web/instance/prod_config.py Please open the file after installation and edit Map Pools and Add Admin IDs"
			
			#WSGI File
			echo "Creating Get5.wsgi"
			wsgi_create
			
			#Apache Config Creation
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