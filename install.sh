#!/bin/bash
set -euo pipefail

printf "\033c"
echo "===================================================="
echo ""                                                                                                 
echo ""                                                                                                 
echo "  ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄        ▄ ▄▄▄▄▄▄▄▄▄▄▄  "
echo " ▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░▌      ▐░▐░░░░░░░░░░░▌ "
echo "  ▀▀▀▀▀█░█▀▀▀▐░█▀▀▀▀▀▀▀█░▐░▌░▌     ▐░▐░█▀▀▀▀▀▀▀▀▀  "
echo "       ▐░▌   ▐░▌       ▐░▐░▌▐░▌    ▐░▐░▌           "
echo "       ▐░▌   ▐░█▄▄▄▄▄▄▄█░▐░▌ ▐░▌   ▐░▐░█▄▄▄▄▄▄▄▄▄  "
echo "       ▐░▌   ▐░░░░░░░░░░░▐░▌  ▐░▌  ▐░▐░░░░░░░░░░░▌ "
echo "       ▐░▌   ▐░█▀▀▀▀▀▀▀█░▐░▌   ▐░▌ ▐░▌▀▀▀▀▀▀▀▀▀█░▌ "
echo "       ▐░▌   ▐░▌       ▐░▐░▌    ▐░▌▐░▌         ▐░▌ "
echo "  ▄▄▄▄▄█░▌   ▐░▌       ▐░▐░▌     ▐░▐░▌▄▄▄▄▄▄▄▄▄█░▌ "
echo " ▐░░░░░░░▌   ▐░▌       ▐░▐░▌      ▐░░▐░░░░░░░░░░░▌ "
echo "  ▀▀▀▀▀▀▀     ▀         ▀ ▀        ▀▀ ▀▀▀▀▀▀▀▀▀▀▀  "
echo ""
echo ""
echo "===================================================="
echo "Welcome to JANS(Just Another Network Server)"
echo "Installation process should be really quick"
echo "We just need you to answer some questions"
echo "We are going to ask for your sudo password in the end"
echo "To finish the installation of the CLI"
echo "===================================================="
echo ""
# ============================================================================================
# Functions to ease development
# ============================================================================================

send_success_message() {
    echo -e $(printf "\e[32m$1\e[0m")
}

send_error_message() {
    echo -e $(printf "\e[31m$1\e[0m")
    exit 255
}

# CHANGE_HOSTNAME="JANS"
CHANGE_HOSTNAME="" 
read -p "Where do you want to change HOSTNAME? [y/n]: " CHANGE_HOSTNAME

if [ "$CHANGE_HOSTNAME" == "y" ]; then
    read -p "Please input your desired HOSTNAME [jans]: " host_name
    host_name=${host_name:-"jans"}
fi

check_dependencides() {
    if command -v $1 &> /dev/null; then
        send_success_message "$1 exists ✅ "
    else
        echo -e $(printf "\e[31m ⚠️ $1 not found! ⚠️\e[0m")
        read -p "Do you want jans to install docker and docker-compose? IT ONLY WORKS ON DEBIAN AND UBUNTU! [y/N]: " install_docker
        install_docker=${install_docker:-"n"}

        if [ "$install_docker" == "y" ]; then
            bash ./docker.sh
        else
            send_error_message "Install docker and docker-compose and come back later!"
        fi
    fi
}

running_services_location() {
    host_ip=$(hostname -I | awk '{ print $1 }')
    echo "Portainer: http://$host_ip:9000/"
    echo "qBittorrent: http://$host_ip:8080/"
    echo "Radarr: http://$host_ip:7878/"
    echo "Sonarr: http://$host_ip:8989/"
    echo "Lidarr: http://$host_ip:8686/"
    echo "Readarr: http://$host_ip:8787/"
    echo "Prowlarr: http://$host_ip:9696/"
    echo "Bazarr: http://$host_ip:6767/"
    echo "Doublecommander: http://$host_ip:3000/"
    echo "Kavita: http://$host_ip:5500/"
    echo "Navidrome: http://$host_ip:4533/"
    echo "Jellyfin: http://$host_ip:8096/"
    if [ "$setup_minio" == "y" ]; then
      echo "MinIO: https://$host_ip:9009/"
    fi
}

# ============================================================================================
# Check all the prerequisites are installed before continuing
# ============================================================================================
echo "Checking prerequisites..."


check_dependencides "docker"
check_dependencides "docker-compose"

# if [[ "$EUID" = 0 ]]; then
#     send_error_message "jans has to run without sudo! Please, run it again with regular permissions"
# fi

# ============================================================================================

# ============================================================================================
# Gathering information
# ============================================================================================
read -p "Where do you want to install the docker-compose file? [/opt/jans]: " install_location

# Checking if the install_location exists
install_location=${install_location:-/opt/jans}
[[ -f "$install_location" ]] || mkdir -p "$install_location" || send_error_message "There was an error with your install location! Make sure the directory exists and the user \"$USER\" has permissions on it"
install_location=$(realpath "$install_location")
filename="$install_location/docker-compose.yaml"

read -p "What's the user that is going to own the media server files? [$USER]: " username

# Checking that the user exists
username=${username:-$USER}

if id -u "$username" &>/dev/null; then
    puid=$(id -u "$username");
    pgid=$(id -g "$username");
else
    send_error_message "The user \"$username\" doesn't exist!"
fi

read -p "Please, input your media folder [/srv/media]: " media_folder
media_folder=${media_folder:-"/srv/media"}

# Checking that the media folder exists

realpath "$media_folder" &>/dev/null || send_error_message "There was an error with your media folder! The directory \"$media_folder\" does not exist!"

media_folder=$(realpath "$media_folder")

read -p "Are you sure your media folder is \"$media_folder\"? [y/N]: " media_folder_correct
media_folder_correct=${media_folder_correct:-"n"}

if [ "$media_folder_correct" == "n" ]; then
    send_error_message "Media folder is not correct. Please, fix it and run the script again"
fi

#Setting the jellyfin port to 8096 as its the default 
media_service_port=8096

# Adding the minio document store
echo
echo
echo
echo "Time to set up the MinIO Storage."
read -p "Do you want to configure a MinIO? [Y/n]: " setup_minio
setup_minio=${setup_minio:-"y"}

if [ "$setup_minio" == "y" ]; then
    echo
    read -p "What's your desired minio username? (without spaces)[administrator]: " minio_user
    minio_user=${minio_user:-"administrator"}
    echo
    unset minio_password
    charcount=0
    prompt="What's your minio password? (Atleast 10 characters in alphanumeric): "
    while IFS= read -p "$prompt" -r -s -n 1 char
    do
        if [[ $char == $'\0' ]]
        then
            break
        fi
        if [[ $char == $'\177' ]] ; then
            if [ $charcount -gt 0 ] ; then
                charcount=$((charcount-1))
                prompt=$'\b \b'
                minio_password="${minio_password%?}"
            else
                prompt=''
            fi
        else
            charcount=$((charcount+1))
            prompt='*'
            minio_password+="$char"
        fi
    done
    echo
fi
echo
echo "Configuring the docker-compose file for the user \"$username\" on \"$install_location\"..."
# ============================================================================================

# ============================================================================================
# Actually installing everything!
# ============================================================================================

# Copy the docker-compose file from the example to the real one
echo ""
echo "Copying $filename..."

cp docker-compose.example.yaml "$filename" || send_error_message "Your user ($USER) needs to have permissions on the installation folder!"

# Set PUID
sed -i -e "s/<your_PUID>/$puid/g" "$filename"

# Set PGID
sed -i -e "s/<your_PGID>/$pgid/g" "$filename"

# Set media_folder
sed -i -e "s;<media_folder>;$media_folder;g" "$filename"

# Set config folder
sed -i -e "s;<install_location>;$install_location;g" "$filename"

# Set minio
if [ "$setup_minio" == "y" ]; then
    sed -i -e "s;<minio_user>;$minio_user;g" "$filename"
    sed -i -e "s;<minio_password>;$minio_password;g" "$filename"
fi

# Set jans script
sed -i -e "s;<filename>;$filename;g" jans
sed -i -e "s;<install_location>;$install_location;g" jans

if [ "$CHANGE_HOSTNAME" == "y" ]; then
	echo "$host_name" > /etc/hostname
	# edit hosts file
#	sudo sed -i "s/raspberrypi/$CHANGE_HOSTNAME/;s/odroid/$CHANGE_HOSTNAME/" /etc/hosts
fi
chmod 666 /etc/hostname

send_success_message "Everything installed correctly! 🎉"

echo "Running the server..."
echo "This is going to take a while...grab a cup of coffee :)"

docker-compose -f "$filename" up -d
# ============================================================================================

# ============================================================================================
# Cleaning up...
# ============================================================================================

send_success_message "We need your sudo password to install the jans CLI and correct permissions..."
sudo cp jans /usr/local/bin/jans && sudo chmod +x /usr/local/bin/jans
[[ -f "$media_folder" ]] || sudo mkdir -p "$media_folder" || send_error_message "There was an error with your install location!"
sudo chown -R "$puid":"$pgid" "$media_folder"
[[ -f $install_location/config ]] || sudo mkdir -p "$install_location/config"
sudo chown -R "$puid":"$pgid" "$install_location"

printf "\033c"
echo "========================================================"
echo ""
echo ""
echo " ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ ▄▄        ▄ ▄▄▄▄▄▄▄▄▄▄▄  "
echo "▐░░░░░░░░░░▌▐░░░░░░░░░░░▐░░▌      ▐░▐░░░░░░░░░░░▌ "
echo "▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀█░▐░▌░▌     ▐░▐░█▀▀▀▀▀▀▀▀▀  "
echo "▐░▌       ▐░▐░▌       ▐░▐░▌▐░▌    ▐░▐░▌           "
echo "▐░▌       ▐░▐░▌       ▐░▐░▌ ▐░▌   ▐░▐░█▄▄▄▄▄▄▄▄▄  "
echo "▐░▌       ▐░▐░▌       ▐░▐░▌  ▐░▌  ▐░▐░░░░░░░░░░░▌ "
echo "▐░▌       ▐░▐░▌       ▐░▐░▌   ▐░▌ ▐░▐░█▀▀▀▀▀▀▀▀▀  "
echo "▐░▌       ▐░▐░▌       ▐░▐░▌    ▐░▌▐░▐░▌           "
echo "▐░█▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄█░▐░▌     ▐░▐░▐░█▄▄▄▄▄▄▄▄▄  "
echo "▐░░░░░░░░░░▌▐░░░░░░░░░░░▐░▌      ▐░░▐░░░░░░░░░░░▌ "
echo " ▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀ ▀        ▀▀ ▀▀▀▀▀▀▀▀▀▀▀  "
echo ""
echo ""
echo "========================================================"
send_success_message "All done!✅  Enjoy JANS!"
echo "You can check the installation on $install_location"
echo "========================================================"
echo "Everything should be running now! To check everything running, go to:"
echo
running_services_location
echo
echo
echo "You might need to wait for a couple of minutes while everything gets up and running"
echo
echo "All the services location are also saved in ~/jans_services.txt"
running_services_location > ~/jans_services.txt
echo "========================================================"
echo
#echo "To configure jans, check the documentation at"
#echo "https://jans.media/config"
echo
echo "========================================================"
exit 0
# ============================================================================================
