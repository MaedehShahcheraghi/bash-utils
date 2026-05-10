#!/bin/bash


Backup_Dir="/tmp/docker_image_backup"
Target_User="maedeh"
Target_Password="0110713486m"
Target_Server="192.168.18.139"
Target_Dest="/home/maedeh/backups/dockerimages/"

mkdir -p "$Backup_Dir"
ls -dt "$Backup_Dir"/*.tar | tail -n +11 | xargs -r rm -f

Containers=$(docker ps -q)

if [ -z "$Containers" ]
then
    echo "No running containers found! Exiting."
    exit 1	
fi

TimeStamp=$(date +"%Y%m%d_%H%M%S")

for Container in $Containers ; do
	Container_Name=$(docker inspect --format="{{.Name}}"  $Container | cut -d "/" -f2)
	Image_Name=$(echo  "backup_${Container_Name}_${TimeStamp}" | tr [:upper:] [:lower:])
	Tar_File="$Backup_Dir/${Image_Name}.tar"

	        echo "Committing container $Container_Name ($Container)..."
		docker commit "$Container" "$Image_Name"


		echo "Saving image to $Tar_File..."
		docker image save "$Image_Name" -o "$Tar_File"
        
	docker rmi "$Image_Name"
done


if ping -c 1 -W 2 "$Target_Server" &> /dev/null; then
    echo "Server is reachable. Starting SCP transfer..."

    
    sshpass -p "$Target_Password"  scp -o StrictHostKeyChecking=no  "$Backup_Dir"/*.tar "$Target_User@$Target_Server:$Target_Dest"

    if [ $? -eq 0 ]; then
        echo "Transfer completed successfully."
    else
        echo "Error: SCP transfer failed."
    fi
else
    echo "Error: Target server is NOT reachable. Skipping transfer."
fi




























