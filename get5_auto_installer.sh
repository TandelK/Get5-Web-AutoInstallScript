#!/bin/bash
# Project: Get5 Web API Auto Installer for PhlexPlexico Get5-Web
# Author: TandelK
# Credits : Splewis , PhlexPlexico , xe1os
# Purpose: Get5 Web API Panel installation script
# Website : 
version="0.99"

## Color Support Functions
greenMessage() {
	echo -e "\\033[32;1m${@}\033[0m"
}

cyanMessage() {
	echo -e "\\033[36;1m${@}\033[0m"
}

redMessage() {
	echo -e "\\033[31;1m${@}\033[0m"
}

yellowMessage() {
	echo -e "\\033[33;1m${@}\033[0m"
}

greenOneLineMessage() {
	echo -en "\\033[32;1m${@}\033[0m"
}

cyanOneLineMessage() {
	echo -en "\\033[36;1m${@}\033[0m"
}

yellowOneLineMessage() {
	echo -en "\\033[33;1m${@}\033[0m"
}

# Checking for Root
if [[ $EUID -ne 0 ]]; then
   redMessage "This script must be run as root as it require packages to be downloaded" 
   exit 1
fi


##Get5 WSGI Create Function
	function wsgi_create()
	{
	if [ -f "/var/www/get5-web/get5.wsgi" ]
	then
		redMessage "Get5.wsgi already exist"
		break;
	else
		if [ ! -d "/var/www/get5-web" ]
		then
			redMessage "Get5 Web Installation not detected , Please install Get5-Web first"
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
			greenMessage "File created sucessfully in /var/www/get5-web/get5.wsgi"
		fi
	fi
	}
	
#Apache Config
	function apacheconfig() 
	{
		cd /etc/apache2/sites-enabled/
		cyanMessage "Please Enter Panel Address without http or https protocol [eg. g5panel.website.com]"
		read sitename
		greenMessage "You have entered $sitename"
		while [[ $sitename == http* || $sitename == https* ]];
		do
			redMessage "Please re-enter Website Address without http or https protocol [eg. g5panel.website.com]"
			read -r sitename
			greenMessage "You have entered $sitename"
		done
		cyanMessage "Enter Admin Email address: "; 
		read adminemail
			
		if [ -f "/etc/apache2/sites-enabled/$sitename.conf" ]
		then
			redMessage "Sitename Apache Config already exist in sites-enabled"
			redMessage "Do you want to delete existing $sitename.conf file"
			read -p "Enter True or False:" sitefile
			while [[ "$sitefile" != @("True"|"False") ]]
				do
				redMessage "You did not select True or False."
				read -p "Enter True or False:" sitefile
			done
			if [ $sitefile == "True" ]
			then
				rm -r /etc/apache2/sites-enabled/$sitename.conf
			else
				redMessage "Please delete the old file or update the file as per your requirement from Official Guides"
				redMessage "File Location is /etc/apache2/sites-enabled/$sitename.conf"
				exit 1
			fi
			else
			greenMessage "Creating Apache Site Configuration File"
			fi 
		
			## HTTP Site Configuration 
			greenMessage "Creating Apache Site config file under /etc/apache2/sites-enabled/$sitename.conf"
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
			cyanMessage "Do you want to use SSL (True or False)"
			read -p "True or False:" ssloption
			while [[ "$ssloption" != @("True"|"False") ]]
			do
				redMessage "You did not select True or False."
				read -p "True or False:" ssloption
			done
				
			if [ $ssloption == "True" ]
			then
				if [ -f "/etc/apache2/sites-enabled/$sitename-ssl.conf" ]
				then
					redMessage "Sitename Apache Config already exist in sites-enabled"
					redMessage "Do you want to delete existing $sitename-ssl.conf file"
					read -p "Enter True or False:" sslfileconf
	
					while [[ "$sslfileconf" != @("True"|"False") ]]
					do
						redMessage "You did not select True or False."
						read sslfileconf
					done
					if [ $sslfileconf == "True" ]
					then
						rm -r /etc/apache2/sites-enabled/$sitename-ssl.conf
					else
						redMessage "Please delete the old file or update the file as per your requirement from Official Guides"
						redMessage "File Location is /etc/apache2/sites-enabled/$sitename-ssl.conf"
						exit 1
					fi
				fi
					
				greenMessage "Enabling SSL Support"
				a2enmod ssl
				##SSL Certificate
				cyanMessage "Please provide your SSL Certificate Path"
				read crtpath
				greenMessage "You have entered $crtpath"
				while [[ ! -f "$crtpath" || ${crtpath##*.} != 'crt' ]];
				do 
					redMessage "Please check if the file exists and it also contains .crt extension"
					read crtpath
					yellowMessage "You have entered $crtpath"
				done
				cyanMessage "Please provide your SSL Private Key Path"
				##SSL Key
				read crtkey
				while [[ ! -f "$crtkey"  || ${crtkey##*.} != 'key' ]];
				do 
					redMessage "Please check the file exists and it also contains .key extension"
					read crtkey
					yellowMessage "You have entered $crtkey"
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
				yellowMessage "SSL Support not activated"
			fi
			greenMessage "Enabling Website"
			a2ensite $sitename
			greenMessage "Restarting Apache2 Service"
			service apache2 restart
	}

##Web Installation
greenMessage "Welcome to Get5 Web Panel Auto Installation script"
echo ""
PS3="Select the option >"

select option in Install Update 'Create WSGI' 'Create Apache Config' 'Create FTP' 'Remove Get5' exit
do
case $option in
	Install)
			#Setting locales
			greenMessage "Setting system locales"
			echo "LC_ALL=en_US.UTF-8" >> /etc/environment
			echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
			echo "LANG=en_US.UTF-8" > /etc/locale.conf
			locale-gen en_US.UTF-8

		if [ -d "/var/www/get5-web" ] 
		then
			redMessage "Installation already done and exist inside /var/www/get5-web ."
		else
			greenMessage "Downloading Dependencies"
				
			cyanMessage "Do you want to use Apt update and Upgrade Commands ?" 
			redMessage "If you are using specific branch / versions for other projects on the panel i would not recommend below option"
			read -p "Apt-get Update and Upgrade. ( True or False) :" aptupdateissue
			while [[ $aptupdateissue != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False:" aptupdateissue
			done
			if [ $aptupdateissue == "True" ]
			then
				sudo apt-get update && apt-get upgrade -y
			fi
			
			sudo apt-get install build-essential software-properties-common -y
	
			sudo apt-get install python-dev python-pip apache2 libapache2-mod-wsgi -y
		
			sudo apt-get install virtualenv libmysqlclient-dev -y

			#Checking Git Package available or not

			cyanMessage "Checking Git Command Status"

			gitavailable='git'
			if ! dpkg -s $gitavailable >/dev/null 2>&1; then
				greenMessage "Installing Git"
				sudo apt-get install $gitavailable 
				else cyanMessage "Git Already Installed"
			fi
			echo ""
			#Checking MySQL Server installed or not

			cyanMessage "Checking MySQL Server Status"
			echo ""
			sqlavailable='mysql-server'
			if ! dpkg -s $sqlavailable >/dev/null 2>&1; then
				greenMessage "Installing MySQL Server"
				sudo apt-get install $sqlavailable 
				service mysql start
				echo ""
				else 
				cyanMessage "MySQL Server already Installed"
				echo ""
			fi
			greenMessage "Restarting MySQL Service"
			#This is due to any systems have any kind of MySQL Errors can be restarted with this.
			service mysql restart
			
			#MYSQL Information
			cyanMessage "MySQL Server User and Database Creation"
			
			get5dbpass="$(openssl rand -base64 12)"
			redMessage "Just for safety if you want to save it Get5 User Password is $get5dbpass"
			yellowMessage "Please enter root user MySQL password!"
			read -p "YOUR SQL ROOT PASSWORD: " -s rootpasswd
			until mysql -u root -p$rootpasswd  -e ";" ; do
				read -p "Can't connect, please retry Root Password: " -s rootpasswd
			done
			
			yellowMessage "Creating Database Get5 with Collate utf8mb4_general_ci"
			mysql -u root -p$rootpasswd -e "CREATE DATABASE get5 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
			
			yellowMessage "Creating Get5 User with Random Password"
			mysql -u root -p$rootpasswd -e "CREATE USER 'get5'@'localhost' IDENTIFIED BY '$get5dbpass';"
			
			yellowMessage "Grant Privileges to Get5 User to Get5 Database"
			mysql -u root -p$rootpasswd -e "GRANT ALL PRIVILEGES ON get5.* TO 'get5'@'localhost' WITH GRANT OPTION;"
			
			yellowMessage "Flushing Privilges"
			mysql -u root -p$rootpasswd -e "FLUSH PRIVILEGES;"
			
			
			echo "" 
			echo ""
			echo ""
			greenMessage "Downloading Get5 Web Panel"

			cd /var/www/
			# Branch Selection
			greenMessage "Github Branch Selection"
			PS3="Select the branch to clone >"
			select branch in master development
			do
				case $branch in
				master)
					yellowMessage "Downloading Master branch"
					git clone https://github.com/PhlexPlexico/get5-web
					cyanMessage "Finish Downloading Master Branch"
					break;
				;;
				development)
					yellowMessage "Downloading Development branch"
					git clone -b development --single-branch https://github.com/PhlexPlexico/get5-web 
					cyanMessage "Finish Downloading Development Branch"
					break;
				;;
				*) 
					redMessage "You didnt select correct Option, Please use selection from above"
				;;
				esac
			done	
			greenMessage "Downloaded in /var/www/get5-web"
	
			cd /var/www/get5-web
			greenMessage "Start Creating Virtual Environment and Download Requirements"

			virtualenv venv
			source venv/bin/activate
			pip install -r requirements.txt
			

			#Prod Config File Creation and settings
			#Copy & Modify Prod Config file
			cyanMessage "Creating Prod Config File"
			cd /var/www/get5-web/instance
			
			cp prod_config.py.default prod_config.py
			
			file="prod_config.py"
		        
			#Steam API Key
			greenMessage "Enter your Steam API Key (https://steamcommunity.com/dev/apikey)"
			read -p "Steam API Key :" steamapi
			while [[ $steamapi == "" ]];
			do
				redMessage "You did not enter anything. Please re-enter Steam API Key"
				read -p "Steam API Key :" steamapi
			done
			echo "Your Steam API Key is $steamapi"
			
			echo ""
			echo ""
			echo ""
			
			#Random Secret Key for Flask Cookies
			greenMessage "Enter Random Secret Key for Flask Cookies"
			read -p "Random Secret Key :" secretkey
			while [[ $secretkey == "" ]];
				do
				redMessage "You did not enter anything. Please re-enter Secret Key"
				read -p "Random Secret Key :" secretkey
			done
			
			echo ""
			echo ""
			echo ""
			
			#Super Admin Steam ID 64
			redMessage "Warning !! Only added Trusted Steam Admins ID as they have access to everything on the Panel \e[39m"
			echo ""
			greenMessage "Super Admin's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
			redMessage "Make sure the Steam ID dont end with [,] in the end"
			read -p "Steam ID 64 of Super Admins :" superadminsteamid
			while [[ $superadminsteamid == "" ]];
				do
				redMessage "You did not enter anything. Please re-enter Super Admin Steam ID 64 Key"
				read -p "Steam ID 64 of Super Admins :" superadminsteamid
			done
			
			echo ""
			echo ""
			echo ""
			
			#Normal Admin's Steam ID 64
			greenMessage "Want to add Normal Admin's Steam ID"
			read -p "True or False: " normaladmin
			while [[ $normaladmin != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False :" normaladmin
			done
			if [ $normaladmin == "True" ]
			then
			cyanMessage "Admin's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
			read -p "Steam ID 64 of Admins :" adminsteamid
			while [[ $adminsteamid == "" ]];
				do
				redMessage "You did not enter anything. Please re-enter Admin Steam ID 64 Key"
				read -p "Steam ID 64 of Admins :" adminsteamid
			done
			fi
			
			echo ""
			echo ""
			echo ""
			
			#Super Admin and Admin only Panel access
			cyanMessage "By Default anyone can login into panel and create matches,server and teams. Do you want panel to be exclusive for your Admins?"
			greenMessage "Only Admins can access webpanel ? (True or False) . No other Steam IDs will be allowed to login inside the Panel"
			redMessage "Alert!! If you want to add Whitelisted Steam IDs please use False!!"
			read -p "True or False :" adminonlypanel
			while [[ "$adminonlypanel" != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read adminonlypanel
			done
			
			echo ""
			echo ""
			echo ""
			
			#Whitelisted Steam ID 64
			if [ $adminonlypanel == "False" ]
			then
				cyanMessage "By Default the panel is open to public to create their own Servers/Teams and Matches. If you want panel should have exclusive access please configure it here properly."
				greenMessage "Want to add Whitelisted Steam ID ?"
				read -p "True or False :" whitelistoption
				while [[ $whitelistoption != @("True"|"False") ]]
					do
					redMessage "Please enter only True or False"
					read -p "True or False :" whitelistoption
				done
				if [ $whitelistoption == "True" ]
				then
					greenMessage "Whitelist's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
					read -p "Steam ID 64 of Whitelist :" whitelistids
					while [[ $whitelistids == "" ]];
					do
						redMessage "You did not enter anything. Please re-enter Whitelist Steam ID 64 Key"
						read -p "Steam ID 64 of Whitelist :" whitelistids
					done
				else
					cyanMessage "The Panel will be open to the Public for Creating Servers/Matches/Teams. Also they can use any Public Servers and Teams created by Super Admins and Admins"
				fi
			fi
			echo ""
			echo ""
			echo ""
			#Spectators Steam IDs
			cyanMessage "By Default anyone on the Game Server will not be allowed in the matches, Everytime Admins have to add Spectators which are like in Game Admins as well as Casters . This function will auto add them to all Servers"
			greenMessage "Want to add Spectators Spectators Steam ID ?"
			read -p "True or False: " spectatoroption
			while [[ $spectatoroption != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False :" spectatoroption
			done
			if [ $spectatoroption == "True" ]
			then
			greenMessage "Spectator's Steam ID 64 (Please ensure values are separated by a comma. eg.id1,id2)"
			read -p "Steam ID 64 of Spectators :" spectatorids
			while [[ $spectatorids == "" ]];
				do
				redMessage "You did not enter anything. Please re-enter Spectators Steam ID 64 Key"
				read -p "Steam ID 64 of Spectators :" spectatorids
			done
			fi
			
			echo ""
			echo ""
			echo ""
			
			#Web Panel Name
			greenMessage "Enter Title Name for Web Panel"
			read -p "Webpanel Title :" wpanelname
			while [[ $wpanelname == "" ]];
				do
				redMessage "You did not enter anything. Please enter the name for Web Panel Title"
				read -p "Webpanel Title :" wpanelname
			done
			
			echo ""
			echo ""
			echo ""

			#Custom Player Names
			greenMessage "Do you want to enable Custom Player Names in Match Use True or False (Case Sensitive)"
			read -p "True or False :" customname 
			while [[ $customname != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False :" customname
			done
			
			echo ""
			echo ""
			echo ""
			
			#Admin Access all Matches
			greenMessage "Can Super Admin Access all the Matches ? Use True or False (Case Sensitive)"
			read -p "True or False :" superadminaccess
			while [[ $superadminaccess != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False :" superadminaccess
			done
			cyanMessage "You have entered $superadminaccess for Admin Can Access all the Matches"

			echo ""
			echo ""
			echo ""
			
			#Create Match Title Text
			greenMessage "Do you want to create Match Title Text Use True or False (Case Sensitive)"
			read -p "True or False :" matchttext 
			while [[ $matchttext != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False :" matchttext
			done
			
			echo ""
			echo ""
			echo ""
			
			#Database Key for Encryption of User Password as well as RCON Passwords of servers.
			dbkey="$(openssl rand -base64 12)"
			yellowMessage "Your DB Key is $dbkey. This will encrypt user passwords in database."
			
			sed -i "s|mysql://user:password@host/db|mysql://get5:$get5dbpass@localhost/get5|g" $file
			sed -i "s|STEAM_API_KEY = '???'|STEAM_API_KEY = '$steamapi'|g" $file
			sed -i "s|SECRET_KEY = '???'|SECRET_KEY = '$secretkey'|g" $file
			sed -i "s|WEBPANEL_NAME = 'Get5'|WEBPANEL_NAME = '$wpanelname'|g" $file
			sed -i "s|CUSTOM_PLAYER_NAMES = True|CUSTOM_PLAYER_NAMES = $customname|g" $file
			sed -i "s|DATABASE_KEY = '???'|DATABASE_KEY = '$dbkey'|g" $file
			sed -i "s|ADMINS_ACCESS_ALL_MATCHES = False|ADMINS_ACCESS_ALL_MATCHES = $superadminaccess|g" $file
			sed -i "s|CREATE_MATCH_TITLE_TEXT = False|CREATE_MATCH_TITLE_TEXT = $matchttext|g" $file
			sed -i "71 s|SUPER_ADMIN_IDS = \[.*\]|SUPER_ADMIN_IDS = ['$superadminsteamid']|g" $file
			echo "['$superadminsteamid']" | sed -i "71 s:,:\',\':g" $file
			
			if [ $normaladmin == "True" ]
			then
				sed -i "66 s|ADMIN_IDS = \[.*\]|ADMIN_IDS = ['$adminsteamid']|g" $file
				echo "['$adminsteamid']" | sed -i "66 s:,:\',\':g" $file
			fi
			
			if [ $adminonlypanel == "True" ]
			then
				if [ $normaladmin == "True" ]
				then
					sed -i "61 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid,$adminsteamid']|g" $file
					echo "['$superadminsteamid','$adminsteamid']" | sed -i "61 s:,:\',\':g" $file
				else
					sed -i "61 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid']|g" $file
					echo "['$superadminsteamid']" | sed -i "61 s:,:\',\':g" $file
				fi
			else
				if [ $whitelistoption == "True" ] 
				then
					if [ $normaladmin == "True" ]
					then
						sed -i "61 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid,$adminsteamid,$whitelistids']|g" $file
						echo "['$superadminsteamid','$adminsteamid','$whitelistids']" | sed -i "61 s:,:\',\':g" $file
					else
						sed -i "61 s|WHITELISTED_IDS = \[.*\]|WHITELISTED_IDS = ['$superadminsteamid,$whitelistids']|g" $file
						echo "['$superadminsteamid','$whitelistids']" | sed -i "61 s:,:\',\':g" $file
					fi
				fi
			fi
			
			if [ $spectatoroption == "True" ]
			then
				sed -i "56 s|SPECTATOR_IDS = \[.*\]|SPECTATOR_IDS = ['$spectatorids']|g" $file
				echo "['$spectatorids']" | sed -i "56 s:,:\',\':g" $file
			fi
			
			echo ""
			echo ""
			echo ""
			
			cyanMessage "File is created under /var/www/get5-web/instance/prod_config.py Please open the file after installation and edit Map Pools and Add User IDs"
			
			echo ""
			echo ""
			echo ""
			
			#Database Creation 
			greenMessage "Creating Database Structure."
			cd /var/www/get5-web/
			
			./manager.py db upgrade
			
			#Changing File Permisions
			greenMessage "Changing File permissions for required folder"
			cd /var/www/get5-web/
			chown -R www-data:www-data logs
			chown -R www-data:www-data get5/static/resource/csgo
			
			echo ""
			echo ""
			echo ""

			#WSGI File
			cyanMessage "Creating Get5.wsgi"
			wsgi_create
			
			echo ""
			echo ""
			echo ""
			
			#Apache Config Creation
			cyanMessage "Creating Apache Config"
			apacheconfig

			echo ""
			echo ""
			echo ""
			
			yellowMessage "Changing Directory back to /var/www/get5-web"
			cd /var/www/get5-web
			
			echo ""
			echo ""
			echo ""
			
			yellowMessage "Changing Directory to /var/www/get5-web/instance. Here you can modify the Map List under prod_config.py file. Please look at the formatting properly."
			cd /var/www/get5-web/instance
			
			echo ""
			echo ""
			echo ""
			
			greenMessage "If you want to Note down some important information if you want to modify anything in future . "
			greenMessage "Database User of get5@localhost is $get5dbpass"
			greenMessage "Database Encryption Password is $dbkey"
			greenMessage "File for modifying for Map Pools is located in /var/www/get5-web/instance/prod_config.py"
			
			break;
		fi
	;;
	Update)
		if [ -d "/var/www/get5-web" ] 
			then
			cd /var/www/get5-web
			greenMessage "Downloading Update" 
			git pull
			greenMessage "Doing Requirement Update"
			source venv/bin/activate
			pip install -r requirements.txt
			greenMessage "Doing manager upgrade command"
			if [ -f "/var/www/get5-web/instance/prod_config.py" ]
			then 
				./manager.py db upgrade
			else
				redMessage "You seems to not have added prod_config.py file"
			fi
			cyanMessage "Restarting Apache2 Service"
			sudo service apache2 restart
			cyanMessage "Update completed. Please do a refresh on webpanel for changes"
			exit 1
			else
			redMessage "Installation Not Found.Please use install option"
			fi
	;;
	'Create WSGI')
		if [ -f "/var/www/get5-web/get5.wsgi" ]
			then
			redMessage "Get5.wsgi already exist"
			else
				if [ -d "/var/www/get5-web" ]
					then
					greenMessage "Creating new WSGI File in /var/www/get5-web/get5.wsgi"
					wsgi_create
					else
					redMessage "Please install the get5-web first"
				fi
		fi		
	;;
	'Create Apache Config')
		if [ -d "/var/www/get5-web" ]
		then
		apacheconfig
		greenMessage "Please check the apache Config file located in /etc/apache2/sites-enabled/$sitename.conf"
		else
		redMessage "You dont seem to have Get5-Web Installed"
		fi
	;;
	'Create FTP')
		if [ -d "/var/www/get5-web" ]
		then
		#FTP User Creation
			if [ $(id -u) -eq 0 ]; then
				read -p "Enter FTP username : " username
				read -s -p "Enter password : " password
				egrep "^$username" /etc/passwd >/dev/null
				if [ $? -eq 0 ]; then
					redMessage "$username already exists!"
					exit 1
				else
					pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
					greenMessage $pass
					useradd -m -p $pass -s /bin/bash $username
					[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
				fi
	
			else
				echo "Only root may add a user to the system"
				exit 2
			fi
			#VSFTPD Installation
			if [ -f "/etc/vsftpd.conf" ]
				then
				yellowMessage "VSFTPD Config already available"
				redMessage "Copying original file to original extension"
				mv /etc/vsftpd.conf /etc/vsftpd.conf.original
			else
				cyanMessage "Checking for vsftpd Installation"
				vsftpdavailable='vsftpd'
				if ! dpkg -s $vsftpdavailable >/dev/null 2>&1; then
					greenMessage "Installing VSFTPD Server"
					sudo apt-get install $vsftpdavailable
					echo ""
					greenMessage "Copying original Config file to .orginal extension"
					mv /etc/vsftpd.conf /etc/vsftpd.conf.original
				fi
			fi
			
			
			
			redMessage "What kind of FTP IP you want to use ?"
			cyanMessage "Localhost - When same PCs are used for CSGO and get5-Web"
			cyanMessage "Internal IP - When Get5-Web is hosted on same Network of CSGO Server in LAN Environment"
			cyanMessage "Recommended - When Get5-Web wants to connect from External IP to different CSGO Host - This option is also recommend for Amazon AWS and other Cloud Services"
			cyanMessage "External IP needs working Internet Connection"
			
			yellowMessage "What kind of IP you want to use ?"
			PS3="Select the IP for FTP Connection>"
			select iptype in 'Localhost' 'Internal IP' 'External IP'
			do 
				case $iptype in
				'Localhost')
					yellowMessage "You have selected Localhost for the FTP IP"
					ip=$"127.0.0.1"
					break;
				;;
				'Internal IP')
					yellowMessage "You have selected Internal IP (Recommend for LAN Servers"
					ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
					break;
				;;
				'External IP')
					greenMessage "Using External IP as the Passive IP Address"
					ip="$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)"
					break;
				;;
				*)
				redMessage "You did not select Correct Option, Please do it again"
				;;
				esac
			done
				
			vsftpd="/etc/vsftpd.conf"
			echo "allow_writeable_chroot=YES" >> $vsftpd
			echo "anon_umask=022" >> $vsftpd
			echo "anon_upload_enable=NO" >> $vsftpd
			echo "anonymous_enable=NO" >> $vsftpd
			echo "ascii_download_enable=YES" >> $vsftpd
			echo "ascii_upload_enable=YES" >> $vsftpd
			echo "chroot_local_user=YES" >> $vsftpd
			echo "connect_from_port_20=YES" >> $vsftpd
			echo "dirmessage_enable=YES" >> $vsftpd
			echo "dual_log_enable=YES" >> $vsftpd
			echo "force_dot_files=YES" >> $vsftpd
			echo "listen=YES" >> $vsftpd
			echo "local_enable=YES" >> $vsftpd
			echo "local_umask=002" >> $vsftpd
			echo "max_clients=100" >> $vsftpd
			echo "max_per_ip=10" >> $vsftpd
			echo "pam_service_name=vsftpd" >> $vsftpd
			echo "pasv_enable=YES" >> $vsftpd
			echo "pasv_address=$ip" >> $vsftpd
			if [[ $iptype == "External IP" ]]
			then
			echo "${ip}" | sed -i 's/"//g' $vsftpd
			fi
			echo "pasv_max_port=12100" >> $vsftpd
			echo "pasv_min_port=12000" >> $vsftpd
			echo "seccomp_sandbox=NO" >> $vsftpd
			echo "tcp_wrappers=YES" >> $vsftpd
			echo "use_localtime=YES" >> $vsftpd
			echo "userlist_deny=NO" >> $vsftpd
			echo "userlist_enable=YES" >> $vsftpd
			echo "userlist_file=/etc/vsftpd.userlist" >> $vsftpd
			echo "write_enable=YES" >> $vsftpd
			echo "xferlog_enable=YES" >> $vsftpd
			echo "xferlog_std_format=YES" >> $vsftpd
	
			# Setting Permissions
			greenMessage "Adding FTP User to VSFTPD Userlist File"
			echo "$username" >> /etc/vsftpd.userlist
			greenMessage "Setting folder permissions for $username"
			sudo usermod -a -G www-data $username
			sudo usermod -d /var/www/get5-web/get5/static/demos $username
			sudo chown -R $username:www-data /var/www/get5-web/get5/static/demos

			greenMessage "Restarting vsftpd service"
			service vsftpd restart
			
			cyanMessage "Please forward the ports range 20-21(tcp) & 12000-12100(tcp)"
			greenMessage "Done."
		else
		redMessage "You dont seem to have Get5-Web Installed"
		fi
	;;
	'Remove Get5')
		if [ ! -d "/var/www/get5-web" ]
		then
			redMessage "Get5-Web Installation not exist in /var/www/get5-web"
			break;
		else
			redMessage "Do you really want to remove Get5-Web Installation"
			read -p "True or False" get5remove
			while [[ $get5remove != @("True"|"False") ]]
				do
				redMessage "Please enter only True or False"
				read -p "True or False :" get5remove
			done
			if [ $get5remove == "True" ]
			then
				redMessage "Removing Get5-Web Directory"
				rm -r /var/www/get5-web/
				redMessage "Removing MySQL Database and User"
				
				yellowMessage "Enter MySQL Root Password"
				read -p "YOUR SQL ROOT PASSWORD: " -s rootpasswd
				until mysql -u root -p$rootpasswd  -e ";" ; do
					read -p "Can't connect, please retry Root Password: " -s rootpasswd
				done
				
				redMessage "Removing MySQL Database"
				mysql -u root -p$rootpasswd -e "DROP DATABASE get5;"
				
				redMessage "Removing MySQL User"
				mysql -u root -p$rootpasswd -e "DROP USER get5@localhost;"
				
				redMessage "Flushing MySQL Privileges"
				mysql -u root -p$rootpasswd -e "FLUSH PRIVILEGES;"
			else
				redMessage "You selected False , Nothing will be deleted"
				exit 1;
			fi
		fi
	;;
	exit)
		redMessage "Exiting Script"
		exit 1
	;;
	*) 		
	redMessage "You didnt select correct Option, Please use selection from above"
	;;
	esac
	done
