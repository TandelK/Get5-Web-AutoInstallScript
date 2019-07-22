# Get5-AutoInstallScript

Are you having hard time installing Get5-Web Panel ? Well here is a quick Auto Install Scirpt created by me for installing https://github.com/PhlexPlexico/get5-web version. The reason why i selected Phlex version is due to advance updates and more options added by him. 

For Installing just simply copy the below code and paste it in Terminal of Ubuntu System.

`wget -O - https://raw.githubusercontent.com/TandelK/Get5-AutoInstallScript/master/get5_auto_installer.sh | bash`

# This Auto Install Script Includes 
1) Install : Selection of Master Branch which is stable as well as Development branch is available 
2) Update : Auto Update the Panel and it will automatically run the Upgrade Commands like Requirements or Migrations upgrade after Updates. 

The below 2 options are generally not required as they are auto created with Install Function

3) Create WSGI : You can manually create WSGI Script if you are having issues.

4) Apache Configuration : If you have Get5-Web Installed and forgot to do Apache2 Config this will help you creating the same. 
The SSL Module will require Certificate File in .crt format as well as Private Key in .key format already existing in the server. Please remember the paths of the SSL Certificate as well as Private Key paths as they are required during HTTPS Version installation. 

5) Exit - Meh !! Just Quit the Script . Why did i even make it function 
