#!/bin/sh

clear

username=$(whoami)

# Getting available disks
disks=$(lsblk -l -o NAME | grep -E '^sd[a-z][0-9]+$|^nvme[0-9]+n[0-9]+p[0-9]+$')

# Show the disks for the user
echo "Available disks:"
for disk in $(lsblk -l -o NAME | grep -E '^sd[a-z][0-9]+$|^nvme[0-9]+n[0-9]+p[0-9]+$'); do
    size=$(lsblk -l -o NAME,SIZE | grep "^$disk" | awk '{print $2}')
    fstype=$(lsblk -l -o NAME,FSTYPE | grep "^$disk" | awk '{print $2}')
    echo "$disk - $size - $fstype"
done

while true; do
    # Ask for a disk to mount
    echo -n "Type the disk you want to auto mount ('exit' to leave): "
    read disk_name
    
    # Interaction exit
    if [ "$disk_name" == "exit" ]; then
        break
    fi
    
    # Verify if the disk is valid
    if echo "$disks" | grep -q "^$disk_name$"; then
        mount_point=$(sudo findmnt -n -o TARGET -S /dev/$disk_name)
        
        if [ -n "$mount_point" ]; then
            echo "$disk_name is already mounted $mount_point, probably you selected the wrong disk"
            continue
        fi

        clear
        echo "Type the Drive Name:"
        read name

        # Script creation
        mkdir -p /home/$username/System/Scripts
        cat << EOF > /home/$username/System/Scripts/mount-$disk_name.sh
#!/bin/sh
mkdir -p /home/$username/System/Devices/$name
sudo mount /dev/$disk_name "/home/$username/System/Devices/$name"
EOF
        chmod +x /home/$username/System/Scripts/mount-$disk_name.sh
        

        # Adding the script load in bashrc
        sed -i "/# Devices/a source /home/$username/System/Scripts/mount-$disk_name.sh" "/home/$username/.bashrc"

        clear
        echo "Available disks:"
        for disk in $(lsblk -l -o NAME | grep -E '^sd[a-z][0-9]+$|^nvme[0-9]+n[0-9]+p[0-9]+$'); do
            size=$(lsblk -l -o NAME,SIZE | grep "^$disk" | awk '{print $2}')
            fstype=$(lsblk -l -o NAME,FSTYPE | grep "^$disk" | awk '{print $2}')
            echo "$disk - $size - $fstype"
        done
    else
        echo "Invalid disk."
    fi
done

# Deleting the script
rm -rf "/home/$username/System/Scripts/generate-mount.sh"