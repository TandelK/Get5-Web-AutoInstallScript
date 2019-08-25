#!/bin/bash
# Project: Get5 Web API Auto Installer for PhlexPlexico Get5-Web
# Author: TandelK
# Credits : Splewis , PhlexPlexico 
# Purpose: Get5 Web API Panel installation script
# Website : 
version="0.80"

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
		if [ ! -d "/var/www/get5-web" ]
		then
			echo "Get5 Web Installation not detected , Please install Get5-Web first"
			break;
		else

			cd /var/www/get5-web
			echo "Creating WSGI Config File"
			echo "#!/usr/bin/python">> /var/www/get5-web/get5.wsgi
			echo "">> /var/www/get5-web/get5.wsgi
			echo "activate_this = '/var/www/get5-web/venv/bin/activate_this.py'">> /var/www/get5-web/get5.wsgi
			echo "execfile(activate_this, dict(__file__=activate_this))">> /var/www/get5-web/get5.wsgi
			echo "">> /var/www/get5-web/get5.wsgi
			echo "import sys">> /var/www/get5-web/get5.wsgi
			echo "import logging">> /var/www/get5-web/get5.wsgi
			echo "logging.basicConfig(stream=sys.stderr)">> /var/www/get5-web/get5.wsgi
			echo "">> /var/www/get5-web/get5.wsgi
			echo 'folder = "/var/www/get5-web"'>> /var/www/get5-web/get5.wsgi
			echo "if not folder in sys.path:">> /var/www/get5-web/get5.wsgi
			echo "    sys.path.insert(0, folder)">> /var/www/get5-web/get5.wsgi
			echo 'sys.path.insert(0,"")'>> /var/www/get5-web/get5.wsgi
			echo "">> /var/www/get5-web/get5.wsgi
			echo "from get5 import app as application">> /var/www/get5-web/get5.wsgi
			echo "import get5">> /var/www/get5-web/get5.wsgi
			echo "get5.register_blueprints()">> /var/www/get5-web/get5.wsgi
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
						
						if [ -f "/etc/apache2/sites-enabled/$sitename.conf"]
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
			echo "Restarting MySQL Service"
			#This is due to any systems have any kind of MySQL Errors can be restarted with this.
			service mysql restart
			
			#MYSQL Information
			echo -e " \e[32m MySQL Server Database Creation \e[39m"
			
			get5dbpass="$(openssl rand -base64 12)"
			echo "Just for safety if you want to save it Get5 User Password is $get5dbpass"
			
			# If /root/.my.cnf exist it will auto create database as it already has MySQL Root Password
			
			if [ -f /root/.my.cnf ];
			then
			
				echo "Creating Database Get5 with Collate utf8mb4_general_ci"
				mysql -e "CREATE DATABASE get5 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
				
				echo "Creating Get5 User with Random Password"
				mysql -e "CREATE USER get5@localhost IDENTIFIED BY '$get5dbpass';"
				
				echo "Grant Privileges to Get5 User to Get5 Database"
				mysql -e "GRANT ALL PRIVILEGES ON get5.* TO 'get5'@'localhost' WITH GRANT OPTION;"
				
				mysql -e "FLUSH PRIVILEGES;"
				
			# If /root/.my.cnf doesn't exist then it'll ask for root password   
			else
				echo "Please enter root user MySQL password!"
					read -p "YOUR SQL ROOT PASSWORD: " -s rootpasswd
					until mysql -u root -p$rootpasswd  -e ";" ; do
					read -p "Can't connect, please retry: " -s rootpasswd
				done
				
				echo "Creating Database Get5 with Collate utf8mb4_general_ci"
				mysql -u root -p$rootpasswd -e "CREATE DATABASE get5 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
				
				echo "Creating Get5 User with Random Password"
				mysql -u root -p$rootpasswd -e "CREATE USER get5@localhost IDENTIFIED BY '$get5dbpass';"
				
				echo "Grant Privileges to Get5 User to Get5 Database"
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
			

			#Prod Config File Creation and settings
			cd /var/www/get5-web/instance
		        
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
				echo "You did not enter anything. Please re-enter Secret Key"
				read secretkey
			done
			
			#Main Admin Steam ID 64
			echo "Admin's Steam ID 64 (Please ensure values are separated by a comma.)"
			read adminsteamid
			while [[ $adminsteamid == "" ]];
				do
				echo "You did not enter anything. Please re-enter Admin Steam ID 64 Key"
				read adminsteamid
			done

			#Web Panel Name
			echo "Enter Name for Web Panel"
			read wpanelname
			while [[ $wpanelname == "" ]];
				do
				echo "You did not enter anything. Please enter the name for Web Panel"
				read wpanelname
			done
			
			#Admin Access all Matches
			echo "Can Admin Access all the Matches ? Use True or False (Case Sensitive)"
			read adminaccess
			while [[ "$adminaccess" != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read adminaccess
			done
			echo "You have entered $adminaccess for Admin Can Access all the Matches"

			#Create Match Title Text
			echo "Do you want to create Match Title Text Use True or False (Case Sensitive)"
			read matchttext 
			while [[ "$matchttext" != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read matchttext
			done
			
			#Database Key for Encryption of User Password as well as RCON Passwords of servers.
			dbkey="$(openssl rand -base64 12)"
			echo "Your DB Key is $dbkey. This will encrypt user passwords in database."
			
			#Copy & Modify Prod Config file
			echo "Creating Prod Config File"
			cd /var/www/get5-web/instance
			
			cp prod_config.py.default prod_config.py
			
			file="prod_config.py"
			
			sed -i "s|mysql://user:password@host/db|mysql://get5:$get5dbpass@localhost/get5|g" $file
			sed -i "s|STEAM_API_KEY = '???'|STEAM_API_KEY = '$steamapi'|g" $file
			sed -i "s|SECRET_KEY = '???'|SECRET_KEY = '$secretkey'|g" $file
			sed -i "s|WEBPANEL_NAME = 'Get5'|WEBPANEL_NAME = '$wpanelname'|g" $file
			sed -i "s|DATABASE_KEY = '???'|DATABASE_KEY = '$dbkey'|g" $file
			sed -i "s|ADMINS_ACCESS_ALL_MATCHES = False|ADMINS_ACCESS_ALL_MATCHES = $adminaccess|g" $file
			sed -i "s|CREATE_MATCH_TITLE_TEXT = False|CREATE_MATCH_TITLE_TEXT = $matchttext|g" $file
			sed -i "62 s|ADMIN_IDS = \[.*\]|ADMIN_IDS = ['$adminsteamid']|g" $file
			echo "['$adminsteamid']" | sed -i "62 s:,:\',\':g" $file
			
			echo "File is created under /var/www/get5-web/instance/prod_config.py Please open the file after installation and edit Map Pools and Add User IDs"

			#Database Creation 
			echo "Creating Database Structure."
			cd /var/www/get5-web/
			
			./manager.py db upgrade
			
			#Changing File Permisions
			echo "Changing File permissions for required folder"
			cd /var/www/get5-web/
			chown -R www-data:www-data logs
			chown -R www-data:www-data get5/static/resource/csgo

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
			if [ -f "/var/www/get5-web/instance/prod_config.py" ]
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
