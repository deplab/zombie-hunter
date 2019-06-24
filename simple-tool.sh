#!/bin/bash


#Define the interface variables
divider===============================
divider=$divider$divider

header="\n %-10s %10s\n"
width=60

#Design the interface
printf "$header" "OPTION" "ACTION"
printf "%$width.${width}s\n" "$divider"
printf "$header" "a" "|| Kill zombies. Use this if the server is slow ||"
printf "%$width.${width}s\n" "$divider"
printf "$header" "b" "|| Unfreeze VNC for a user ||"
printf "%$width.${width}s\n" "$divider"
printf "$header" "c" "|| Reset user. Use this if a user is locked out due to many failed login attempts ||"
printf "%$width.${width}s\n" "$divider"
printf "$header" "d" "|| Reset password for a user ||"
printf "%$width.${width}s\n" "$divider"
printf "$header" "e" "|| Create new user ||"
printf "%$width.${width}s\n" "$divider"
printf "$header" "f" "|| Delete an existing user ||"
printf "%$width.${width}s\n" "$divider"
printf "%$width.${width}s\n" "$divider"

#Ask for user input to choose one of the options above
echo -n ">>> Choose one of the options above and press {Enter} "
read i

#Check number of zombies
nZombies=$(top -bn1 | grep zombie | awk '{ print $10 }')

#Execute the imput choice
case "$i" in

    #Kill Zombies
    "a") if [ $nZombies -gt 0 ]; then  #Check if number of zombies is greater than 0
             controller=0   #Define controller for a the loop below to kill zombie mother and skip further appearances of the PID
             for m in $(ps -eo stat,ppid | grep -w Z | awk '{ print $2 }'); do
                 if [ $controller == $m ]; then
                     true    #Skip if the PID was killed previously
                 else
                     sudo kill -9 $m    #Kill the PID
                     controller=$m    #Assign the current PID to $controller for further checks in the loop
                 fi
             done

             #Kill child zombie processes
             for c in $(ps aux | grep -w Z | grep -v grep | awk '{ print $2 }'); do
                 sudo kill -9 $c
             done
             echo ">>> All $nZombies zombies were killed successfully"

         #Prompt if there were no zombies running
         else
             echo ">>> No zombies were found"
         fi
         ;;

    #Kill remmina process for a user
    "b") echo -n ">>> Enter a username you want to unfreeze the VNC for and press {Enter} "

         #Get remmina PID associated with the user
         read j
         remminaPID=$(ps aux | grep $j | grep remmina | grep Ssl | awk '{ print $2 }')

         #Check whether or not remmina is running for the user. Kill it if it does, skip if it does not.
         if [ -z $remminaPID ]; then
             echo ">>> No VNC connection was frozen for $j"
         else
             sudo kill $(ps aux | grep $j | grep remmina | grep Ssl | awk '{ print $2 }')
             echo ">>> VNC client is closed for $j"
         fi
         ;;

    #Unlock a user
    "c") echo -n ">>> Enter a username of the user you want to unlock and press {Enter} "

         #Unlock a user
         read j
         lockCheck=$(sudo pam_tally2 --user=$j | grep $j | awk '{ print $2 }')
         if [ $lockCheck -gt 0 ]; then
             sudo pam_tally2 --user=$j --reset
             echo ">>> $j user has been unlocked successfully"
         else
             echo ">>> $j user is not locked, if $j still cannot login, please, try resetting the password for $j"
         fi
         ;;

    #Change password for a user
    "d") echo -n ">>> Enter a username you want to change a password for and press {Enter} "

         #Reset password for a user
         read j
         sudo passwd $j
         ;;

    #Create a new user and promt to either add the new user to sudoers or not. After creating the user copy remmina files shortcuts to the new user, fix ownership after co$
    "e") echo -n ">>> Enter a username for the new user and press {Enter} "

         #Create the user
         read iuser
         sudo adduser $iuser

         #Copy desktop and RDP client files for the new user and fix the ownership
         sudo cp -r /home/root01/.remmina /home/$iuser
         sudo cp -r /home/root01/Desktop /home/$iuser
         sudo cp /home/root01/automate.sh /home/$iuser/auto
         sudo chown -R $iuser:$iuser /home/$iuser

         #Prompt user to check whether or not the new user has to be a sudoer
         echo -n ">>> Would you like to grant this user Administrative privelegies? Type yes or no - all lowercase "

         #Add user to the sudoers or skip if user does not need to be a sudoer
         read j
         if [ $j == "yes" ]; then
             sudo usermod -aG sudo $iuser
             echo ">>> $iuser user has got admin privilegies now. Good luck!"
         else
             true
         fi
         echo ">>> $iuser has been created successfully"
         ;;

    #Remove a user
    "f") echo -n ">>> Enter a username of the user you would like to remove and press {Enter} "

         #Remove a user with associated directory
         read j
         sudo userdel -fr $j
         echo ">>> $j has been deleted successfully"
         ;;

    #Wildcard for handling unexpected inputs
    *) echo ">>> Command was not recognised. This script can understand just 'a', 'b', 'c', 'd', 'e' and 'f' commands, all in lowercase. Please, try again"
    exit 1
    ;;
esac

#Footer
printf "%$width.${width}s\n" "$divider"
echo ">>> Thanks for using this awesome tool!"
