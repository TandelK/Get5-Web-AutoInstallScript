#!/bin/bash
# Project: Get5 Web API Auto Installer for PhlexPlexico Get5-Web
# Author: TandelK
# Credits : Splewis , PhlexPlexico 
# Purpose: Get5 Web API Panel installation script
# Website : 
version="0.95"

# Checking for Root
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
			wsgifile="get5.wsgi"
			echo "Creating WSGI Config File"
			echo "#!/usr/bin/python">> $wsgifile
			echo "">> $wsgifile
			echo "activate_this = '/var/www/get5-web/venv/bin/activate_this.py'">> $wsgifile
			echo "execfile(activate_this, dict(__file__=activate_this))">> $wsgifile
			echo "">> $wsgifile
			echo "import sys">> $wsgifile
			echo "import logging">> $wsgifile
			echo "logging.basicConfig(stream=sys.stderr)">> $wsgifile
			echo "">> $wsgifile
			echo 'folder = "/var/www/get5-web"'>> $wsgifile
			echo "if not folder in sys.path:">> $wsgifile
			echo "    sys.path.insert(0, folder)">> $wsgifile
			echo 'sys.path.insert(0,"")'>> $wsgifile
			echo "">> $wsgifile
			echo "from get5 import app as application">> $wsgifile
			echo "import get5">> $wsgifile
			echo "get5.register_blueprints()">> $wsgifile
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
			
		if [ -f "/etc/apache2/sites-enabled/$sitename.conf" ]
		then
			echo "Sitename Apache Config already exist in sites-enabled"
			echo "Do you want to delete existing $sitename.conf file"
			read -p "Enter Yes or No:" sitefile
			while [[ "$sitefile" != @("Yes"|"No") ]]
				do
				echo "You did not select Yes or No."
				read -p "Yes or No" sitefile
			done
			if [ $sitefile == "Yes" ]
			then
				rm -r /etc/apache2/sites-enabled/$sitename.conf
			else
				echo "Please delete the old file or update the file as per your requirement from Official Guides"
				echo "File Location is /etc/apache2/sites-enabled/$sitename.conf"
				exit 1
			fi
			else
			echo "Creating Apache Site Configuration File"
			fi 
		
			## HTTP Site Configuration 
			echo "Creating Apache Site config file under /etc/apache2/sites-enabled/$sitename.conf"
			echo "<VirtualHost *:80>" >>$sitename.conf
			echo "	ServerName $sitename" >>$sitename.conf
			echo "	ServerAdmin $adminemail" >>$sitename.conf
			echo "	WSGIScriptAlias / /var/www/get5-web/get5.wsgi" >>$sitename.conf
			echo "" >>$sitename.conf
			echo "	<Directory /var/www/get5>" >>$sitename.conf
			echo "		Order deny,allow" >>$sitename.conf
			echo "		Allow from all" >>$sitename.conf
			echo "	</Directory>" >>$sitename.conf
			echo "">>$sitename.conf
			echo "	Alias /static /var/www/get5-web/get5/static" >>$sitename.conf
			echo "	<Directory /var/www/get5-web/get5/static>" >>$sitename.conf
			echo "		Order allow,deny" >>$sitename.conf
			echo "		Allow from all" >>$sitename.conf
			echo "	</Directory>" >>$sitename.conf
			echo "" >>$sitename.conf
			echo "	ErrorLog \${APACHE_LOG_DIR}/error.log" >>$sitename.conf
			echo "	LogLevel warn" >>$sitename.conf
			echo "	CustomLog \${APACHE_LOG_DIR}/access.log combined" >>$sitename.conf
			echo "</VirtualHost>" >>$sitename.conf

			##SSL Support
			echo "Do you want to use SSL (Yes or No)"
			read ssloption
			while [[ "$ssloption" != @("Yes"|"No") ]]
			do
				echo "You did not select Yes or No."
				read ssloption
			done
				
			if [ $ssloption == "Yes" ]
			then
				if [ -f "/etc/apache2/sites-enabled/$sitename-ssl.conf" ]
				then
					echo "Sitename Apache Config already exist in sites-enabled"
					echo "Do you want to delete existing $sitename-ssl.conf file"
					read -p "Enter Yes or No" sslfileconf
	
					while [[ "$sslfileconf" != @("Yes"|"No") ]]
					do
						echo "You did not select Yes or No."
						read sslfileconf
					done
					if [ $sslfileconf == "Yes" ]
					then
						rm -r /etc/apache2/sites-enabled/$sitename-ssl.conf
					else
						echo "Please delete the old file or update the file as per your requirement from Official Guides"
						echo "File Location is /etc/apache2/sites-enabled/$sitename-ssl.conf"
						exit 1
					fi
				fi
					
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
				echo "Please provide your SSL Private Key Path"
				##SSL Key
				read crtkey
				while [[ ! -f "$crtkey"  || ${crtkey##*.} != 'key' ]];
				do 
					echo "Please check the file exists and it also contains .key extension"
					read crtkey
					echo "You have entered $crtkey"
				done
					
				##Apache Site Config for Port 443
				echo "<IfModule mod_ssl.c>">>$sitename-ssl.conf
				echo "<VirtualHost *:443>" >>$sitename-ssl.conf
				echo "	ServerName $sitename" >>$sitename-ssl.conf
				echo "	ServerAdmin $adminemail" >>$sitename-ssl.conf
				echo "	WSGIScriptAlias / /var/www/get5-web/get5.wsgi" >>$sitename-ssl.conf
				echo "" >>$sitename-ssl.conf
				echo "	<Directory /var/www/get5>" >>$sitename-ssl.conf
				echo "		Order deny,allow" >>$sitename-ssl.conf
				echo "		Allow from all" >>$sitename-ssl.conf
				echo "	</Directory>" >>$sitename-ssl.conf
				echo "">>$sitename-ssl.conf
				echo "	Alias /static /var/www/get5-web/get5/static" >>$sitename-ssl.conf
				echo "	<Directory /var/www/get5-web/get5/static>" >>$sitename-ssl.conf
				echo "		Order allow,deny" >>$sitename-ssl.conf
				echo "		Allow from all" >>$sitename-ssl.conf
				echo "	</Directory>" >>$sitename-ssl.conf
				echo "" >>$sitename-ssl.conf
				echo "	ErrorLog \${APACHE_LOG_DIR}/error.log" >>$sitename-ssl.conf
				echo "	LogLevel warn" >>$sitename-ssl.conf
				echo "	CustomLog \${APACHE_LOG_DIR}/access.log combined" >>$sitename-ssl.conf
				echo "">>$sitename-ssl.conf
				echo "	SSLEngine on">>$sitename-ssl.conf
				echo "	SSLCertificateFile $crtpath">>$sitename-ssl.conf
				echo "	SSLCertificateKeyFile $crtkey">>$sitename-ssl.conf
				echo "">>$sitename-ssl.conf
				echo '	<FilesMatch "\.(cgi|shtml|phtml|php)$">'>>$sitename-ssl.conf
				echo "	SSLOptions +StdEnvVars">>$sitename-ssl.conf
				echo "	</FilesMatch>">>$sitename-ssl.conf
				echo "	<Directory /usr/lib/cgi-bin>">>$sitename-ssl.conf
				echo "	SSLOptions +StdEnvVars">>$sitename-ssl.conf
				echo "	</Directory>">>$sitename-ssl.conf
				echo "	</VirtualHost>" >>$sitename-ssl.conf
				echo "	</IfModule>">>$sitename-ssl.conf
			else
				echo "SSL Support not activated"
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
			#Setting locales
			echo "Setting system locales"
			echo "LC_ALL=en_US.UTF-8" >> /etc/environment
			echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
			echo "LANG=en_US.UTF-8" > /etc/locale.conf
			locale-gen en_US.UTF-8

		if [ -d "/var/www/get5-web" ] 
		then
			echo "Installation already done and exist inside /var/www/get5-web ."
		else
			echo -e "\e[32m Downloading Dependencies \e[39m"
				
			echo "Do you want to use Apt update and Upgrade Commands ?" 
			echo "If you are using specific branch / versions for other projects on the panel i would not recommend below option"
			read -p "Apt-get Update and Upgrade. ( Yes or No) :" aptupdateissue
			while [[ $aptupdateissue != @("Yes"|"No") ]]
				do
				echo "Please enter only Yes or No"
				read -p "Yes or No :" aptupdateissue
			done
			if [ $aptupdateissue == "Yes" ]
			then
				sudo apt-get update && apt-get upgrade -y
			fi
			
			sudo apt-get install build-essential software-properties-common -y
	
			sudo apt-get install python-dev python-pip apache2 libapache2-mod-wsgi -y
		
			sudo apt-get install virtualenv libmysqlclient-dev -y

			#Checking Git Package available or not

			echo -e "\e[32m Checking Git Command Status \e[39m"

			gitavailable='git'
			if ! dpkg -s $gitavailable >/dev/null 2>&1; then
				echo -e"\e[32m Installing Git"
				sudo apt-get install $gitavailable 
				else echo -e "\e[32m Git Already Installed \e[39m"
			fi
			echo ""
			#Checking MySQL Server installed or not

			echo -e "\e[32m Checking MySQL Server Status \e[39m"
			echo ""
			sqlavailable='mysql-server'
			if ! dpkg -s $sqlavailable >/dev/null 2>&1; then
				echo -e"\e[32m Installing MySQL Server"
				sudo apt-get install $sqlavailable 
				service mysql start
				echo ""
				else 
				echo -e "\e[32m MySQL Server already Installed \e[39m"
				echo ""
			fi
			echo "Restarting MySQL Service"
			#This is due to any systems have any kind of MySQL Errors can be restarted with this.
			service mysql restart
			
			#MYSQL Information
			echo -e " \e[32m MySQL Server Database Creation \e[39m"
			
			get5dbpass="$(openssl rand -base64 12)"
			echo "Just for safety if you want to save it Get5 User Password is $get5dbpass"
			echo "Please enter root user MySQL password!"
			read -p "YOUR SQL ROOT PASSWORD: " -s rootpasswd
			until mysql -u root -p$rootpasswd  -e ";" ; do
				read -p "Can't connect, please retry Root Password: " -s rootpasswd
			done
			
			echo "Creating Database Get5 with Collate utf8mb4_general_ci"
			mysql -u root -p$rootpasswd -e "CREATE DATABASE get5 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
			
			echo "Creating Get5 User with Random Password"
			mysql -u root -p$rootpasswd -e "CREATE USER get5@localhost IDENTIFIED BY '$get5dbpass';"
			
			echo "Grant Privileges to Get5 User to Get5 Database"
			mysql -u root -p$rootpasswd -e "GRANT ALL PRIVILEGES ON get5.* TO 'get5'@'localhost' WITH GRANT OPTION;"
			
			echo "Flushing Privilges"
			mysql -u root -p$rootpasswd -e "FLUSH PRIVILEGES;"
			
			
			echo "" 
			echo ""
			echo ""
			echo -e "\e[32m Downloading Get5 Web Panel \e[39m"

			cd /var/www/
			# Branch Selection
			echo -e "\e[34m Github Branch Selection \e[39m"
			PS3="Select the branch to clone >"
			select branch in master development gamersguild
			do
				case $branch in
				master)
					echo -e "\e[34m Downloading Master branch \e[39m"
					git clone https://github.com/xe1os/get5-web
					echo -e "\e[34m Finish Downloading Master Branch \e[39m"
					break;
				;;
				development)
					echo -e "\e[34m Downloading Development branch \e[39m"
					git clone -b development --single-branch https://github.com/xe1os/get5-web 
					echo -e "\e[34m Finish Downloading Development Branch \e[39m"
					break;
				;;
				gamersguild)
                    echo -e "\e[34m Downloading GamersGuild branch \e[39m"
                    git clone -b gamersguild --single-branch https://github.com/xe1os/get5-web
                    echo -e "\e[34m Finish Downloading GamersGuild Branch \e[39m"
                    break;
				;;
				*) 
					echo -e "\e[31m You didnt select correct Option, Please use selection from above \e[39m"
				;;
				esac
			done	
			echo -e "\e[34m Downloaded in /var/www/get5-web \e[39m"
	
			cd /var/www/get5-web
			echo "Start Creating Virtual Environment and Download Requirements"

			virtualenv venv
			source venv/bin/activate
			pip install -r requirements.txt
			

			#Prod Config File Creation and settings
			#Copy & Modify Prod Config file
			echo "Creating Prod Config File"
			cd /var/www/get5-web/instance
			
			cp prod_config.py.default prod_config.py
			
			file="prod_config.py"
		        
			#Steam API Key
			echo "Enter your Steam API Key (https://steamcommunity.com/dev/apikey)"
			read -p "Steam API Key :" steamapi
			while [[ $steamapi == "" ]];
			do
				echo "You did not enter anything. Please re-enter Steam API Key"
				read -p "Steam API Key :" steamapi
			done
			echo "Your Steam API Key is $steamapi"
			
			echo ""
			echo ""
			echo ""
			
			#Random Secret Key for Flask Cookies
			echo "Enter Random Secret Key for Flask Cookies"
			read -p "Random Secret Key :" secretkey
			while [[ $secretkey == "" ]];
				do
				echo "You did not enter anything. Please re-enter Secret Key"
				read -p "Random Secret Key :" secretkey
			done
			
			echo ""
			echo ""
			echo ""
			
			#Super Admin Steam ID 64
			echo -e "\e[31m Warning !! Only added Trusted Steam Admins ID as they have access to everything on the Panel \e[39m"
			echo ""
			echo "Super Admin's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
			read -p "Steam ID 64 of Super Admins :" superadminsteamid
			while [[ $superadminsteamid == "" ]];
				do
				echo "You did not enter anything. Please re-enter Super Admin Steam ID 64 Key"
				read -p "Steam ID 64 of Super Admins :" superadminsteamid
			done
			
			echo ""
			echo ""
			echo ""
			
			#Normal Admin's Steam ID 64
			echo "Want to add Normal Admin's Steam ID"
			read -p "True or False: " normaladmin
			while [[ $normaladmin != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read -p "True or False :" normaladmin
			done
			if [ $normaladmin == "True" ]
			then
			echo "Admin's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
			read -p "Steam ID 64 of Admins :" adminsteamid
			while [[ $adminsteamid == "" ]];
				do
				echo "You did not enter anything. Please re-enter Admin Steam ID 64 Key"
				read -p "Steam ID 64 of Admins :" adminsteamid
			done
			fi
			
			echo ""
			echo ""
			echo ""
			
			#Super Admin and Admin only Panel access
			echo "By Default anyone can login into panel and create matches,server and teams. Do you want panel to be exclusive for your Admins?"
			echo "Only Admins can access webpanel ? (True or False) . No other Steam IDs will be allowed to login inside the Panel"
			echo "Alert!! If you want to add Whitelisted Steam IDs please use False!!"
			read -p "True or False :" adminonlypanel
			while [[ "$adminonlypanel" != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read adminonlypanel
			done
			
			echo ""
			echo ""
			echo ""
			
			#Whitelisted Steam ID 64
			if [ $adminonlypanel == "False" ]
			then
				echo "By Default the panel is open to public to create their own Servers/Teams and Matches. If you want panel should have exclusive access please configure it here properly."
				echo "Want to add Whitelisted Steam ID ?"
				read -p "True or False :" whitelistoption
				while [[ $whitelistoption != @("True"|"False") ]]
					do
					echo "Please enter only True or False"
					read -p "True or False :" whitelistoption
				done
				if [ $whitelistoption == "True" ]
				then
					echo "Whitelist's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
					read -p "Steam ID 64 of Whitelist :" whitelistids
					while [[ $whitelistids == "" ]];
					do
						echo "You did not enter anything. Please re-enter Whitelist Steam ID 64 Key"
						read -p "Steam ID 64 of Whitelist :" whitelistids
					done
				else
					echo "The Panel will be open to the Public for Creating Servers/Matches/Teams. Also they can use any Public Servers and Teams created by Super Admins and Admins"
				fi
			fi
			echo ""
			echo ""
			echo ""
			#Spectators Steam IDs
			echo "By Default anyone on the Game Server will not be allowed in the matches, Everytime Admins have to add Spectators which are like in Game Admins as well as Casters . This function will auto add them to all Servers"
			echo "Want to add Spectators Spectators Steam ID ?"
			read -p "True or False: " spectatoroption
			while [[ $spectatoroption != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read -p "True or False :" spectatoroption
			done
			if [ $spectatoroption == "True" ]
			then
			echo "Spectator's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
			read -p "Steam ID 64 of Spectators :" spectatorids
			while [[ $spectatorids == "" ]];
				do
				echo "You did not enter anything. Please re-enter Spectators Steam ID 64 Key"
				read -p "Steam ID 64 of Spectators :" spectatorids
			done
			fi
			
			echo ""
			echo ""
			echo ""
			
			#Web Panel Name
			echo "Enter Title Name for Web Panel"
			read -p "Webpanel Title :" wpanelname
			while [[ $wpanelname == "" ]];
				do
				echo "You did not enter anything. Please enter the name for Web Panel Title"
				read -p "Webpanel Title :" wpanelname
			done
			
			echo ""
			echo ""
			echo ""

			#Custom Player Names
			echo "Do you want to enable Custom Player Names in Match Use True or False (Case Sensitive)"
			read -p "True or False :" customname 
			while [[ $customname != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read -p "True or False :" customname
			done
			
			echo ""
			echo ""
			echo ""
			
			#Admin Access all Matches
			echo "Can Super Admin Access all the Matches ? Use True or False (Case Sensitive)"
			read -p "True or False :" superadminaccess
			while [[ $superadminaccess != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read -p "True or False :" superadminaccess
			done
			echo "You have entered $superadminaccess for Admin Can Access all the Matches"

			echo ""
			echo ""
			echo ""
			
			#Create Match Title Text
			echo "Do you want to create Match Title Text Use True or False (Case Sensitive)"
			read -p "True or False :" matchttext 
			while [[ $matchttext != @("True"|"False") ]]
				do
				echo "Please enter only True or False"
				read -p "True or False :" matchttext
			done
			
			echo ""
			echo ""
			echo ""
			
			#Database Key for Encryption of User Password as well as RCON Passwords of servers.
			dbkey="$(openssl rand -base64 12)"
			echo "Your DB Key is $dbkey. This will encrypt user passwords in database."
			
			sed -i "s|mysql://user:password@host/db|mysql://get5:$get5dbpass@localhost/get5|g" $file
			sed -i "s|STEAM_API_KEY = '???'|STEAM_API_KEY = '$steamapi'|g" $file
			sed -i "s|SECRET_KEY = '???'|SECRET_KEY = '$secretkey'|g" $file
			sed -i "s|WEBPANEL_NAME = 'Get5'|WEBPANEL_NAME = '$wpanelname'|g" $file
			sed -i "s|CUSTOM_PLAYER_NAMES = True|CUSTOM_PLAYER_NAMES = $customname|g" $file
			sed -i "s|DATABASE_KEY = '???'|DATABASE_KEY = '$dbkey'|g" $file
			sed -i "s|ADMINS_ACCESS_ALL_MATCHES = False|ADMINS_ACCESS_ALL_MATCHES = $superadminaccess|g" $file
			sed -i "s|CREATE_MATCH_TITLE_TEXT = False|CREATE_MATCH_TITLE_TEXT = $matchttext|g" $file
			sed -i "67 s|SUPER_ADMIN_IDS = \[.*\]|SUPER_ADMIN_IDS = ['$superadminsteamid']|g" $file
			echo "['$superadminsteamid']" | sed -i "67 s:,:\',\':g" $file
			
			if [ $normaladmin == "True" ]
			then
				sed -i "63 s|ADMIN_IDS = \[.*\]|ADMIN_IDS = ['$adminsteamid']|g" $file
				echo "['$adminsteamid']" | sed -i "63 s:,:\',\':g" $file
			fi
			
			if [ $adminonlypanel == "True" ]
			then
				if [ $normaladmin == "True" ]
				then
					sed -i "59 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid,$adminsteamid']|g" $file
					echo "['$superadminsteamid','$adminsteamid']" | sed -i "59 s:,:\',\':g" $file
				else
					sed -i "59 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid']|g" $file
					echo "['$superadminsteamid']" | sed -i "59 s:,:\',\':g" $file
				fi
			else
				if [ $whitelistoption == "True" ] 
				then
					if [ $normaladmin == "True" ]
					then
						sed -i "59 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid,$adminsteamid,$whitelistids']|g" $file
						echo "['$superadminsteamid','$adminsteamid','$whitelistids']" | sed -i "59 s:,:\',\':g" $file
					else
						sed -i "59 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid,$whitelistids']|g" $file
						echo "['$superadminsteamid','$whitelistids']" | sed -i "59 s:,:\',\':g" $file
					fi
				fi
			fi
			
			if [ $spectatoroption == "True" ]
			then
				sed -i "55 s|SPECTATOR_IDS = \[.*\]|SPECTATOR_IDS = ['$spectatorids']|g" $file
				echo "['$spectatorids']" | sed -i "55 s:,:\',\':g" $file
			fi
			
			echo ""
			echo ""
			echo ""
			
			echo "File is created under /var/www/get5-web/instance/prod_config.py Please open the file after installation and edit Map Pools and Add User IDs"
			
			echo ""
			echo ""
			echo ""
			
			#Database Creation 
			echo "Creating Database Structure."
			cd /var/www/get5-web/
			
			./manager.py db upgrade
			
			#Changing File Permisions
			echo "Changing File permissions for required folder"
			cd /var/www/get5-web/
			chown -R www-data:www-data logs
			chown -R www-data:www-data get5/static/resource/csgo
			
			echo ""
			echo ""
			echo ""

			#WSGI File
			echo "Creating Get5.wsgi"
			wsgi_create
			
			echo ""
			echo ""
			echo ""
			
			#Apache Config Creation
			echo "Creating Apache Config"
			apacheconfig

			echo ""
			echo ""
			echo ""

			#Disabling default apache2 site
			echo "Disabled default apache2 site"
			a2dissite 000-default.conf
			
			echo ""
			echo ""
			echo ""
			
			echo "Changing Directory back to /var/www/get5-web"
			cd /var/www/get5-web
			
			echo ""
			echo ""
			echo ""
			
			echo "Changing Directory to /var/www/get5-web/instance. Here you can modify the Map List under prod_config.py file. Please look at the formatting properly."
			cd /var/www/get5-web/instance
			
			echo ""
			echo ""
			echo ""
			
			echo "If you want to Note down some important information if you want to modify anything in future . "
			echo "Database User of get5@localhost is $get5dbpass"
			echo "Database Encryption Password is $dbkey"
			echo "File for modifying for Map Pools is located in /var/www/get5-web/instance/prod_config.py"
			
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
