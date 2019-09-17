# Get5-AutoInstallScript

Are you having hard time installing Get5-Web Panel ? Well here is a quick Auto Install Script created by me for installing https://github.com/PhlexPlexico/get5-web version. The reason why i selected Phlex version is due to advance updates and more options added by him. 

For Installing just simply copy the below code and paste it in Terminal of Ubuntu System. Currently i have only support for Ubuntu System most trusted 16.04 LTS Version. For any other Distro you are free to modify the Script as per requirement and can also send Pull Request to this Repo. 

<<<<<<< HEAD
`wget https://raw.githubusercontent.com/xe1os/Get5-AutoInstallScript/development-testing/get5_auto_installer.sh && chmod +x get5_auto_installer.sh`
=======
`wget https://raw.githubusercontent.com/xe1os/Get5-AutoInstallScript/master/get5_auto_installer.sh && chmod +x get5_auto_installer.sh`
>>>>>>> ce49e98455ace807ac62a6ee63266e5281fe52d3

`./get5_auto_installer.sh`

The reason why wget Bash script does not work is due to selection base in start

## This Auto Install Script Includes 

1) Install : Selection of Master Branch which is stable as well as Development branch is available 

2) Update : Auto Update the Panel and it will automatically run the Upgrade Commands like Requirements or Migrations upgrade after Updates. 

The below 2 options are generally not required as they are auto created with Install Function

3) Create WSGI : You can manually create WSGI Script if you are having issues.

4) Apache Configuration : If you have Get5-Web Installed and forgot to do Apache2 Config this will help you creating the same. 
The SSL Module will require Certificate File in .crt format as well as Private Key in .key format already existing in the server. Please remember the paths of the SSL Certificate as well as Private Key paths as they are required during HTTPS Version installation. 

5) Exit - Meh !! Just Quit the Script . Why did i even make it function 

Notes : 
Sometime after update of development branch i would recommend you to manually check prod_config file if there are any updates.


## Credits
1) Splewis - For the original Get5 Plugin - https://github.com/splewis/get5
2) PhlexPlexico - For his wonderful modification to Get5-Web version will all new functions - https://github.com/PhlexPlexico/get5-web
3) xe1os - For testing and helping out fix problems

If anyone wants to share some love please sponsors to two major developers here Splewis and PhlexPlexico for their time given to this projects. 
