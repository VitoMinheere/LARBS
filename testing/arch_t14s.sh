#!/bin/bash

#This is a lazy script I have for auto-installing Arch.
#It's not officially part of LARBS, but I use it for testing.
#DO NOT RUN THIS YOURSELF because Step 1 is it reformatting /dev/sda WITHOUT confirmation,
#which means RIP in peace qq your data unless you've already backed up all of your drive.

pacman -S --noconfirm dialog || { echo "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; exit; }

dialog --defaultno --title "DON'T BE A BRAINLET!" --yesno "This is an Arch install script that uses UEFI to boot.\n\nOnly run this script on newer Thinkpads which only have UEFI.\n\nWill delete all data on nvme0n1\n\n"  15 60 || exit

dialog --defaultno --title "DON'T BE A BRAINLET!" --yesno "Do you think I'm meming? Only select yes to DELETE your entire /dev/nvme0n1 and reinstall Arch.\n\nTo stop this script, press no."  10 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." 10 60 2> comp

dialog --defaultno --title "Time Zone select" --yesno "Do you want use the default time zone(Europe/Amsterdam)?.\n\nPress no for select your own time zone"  10 60 && echo "Europe/Amsterdam" > tz.tmp || tzselect > tz.tmp

dialog --no-cancel --inputbox "Enter partitionsize in gb, separated by space (swap & root)." 10 60 2>psize

pass1=$(dialog --no-cancel --passwordbox "Enter a root password." 10 60 3>&1 1>&2 2>&3 3>&1)
pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)

while true; do
	[[ "$pass1" != "" && "$pass1" == "$pass2" ]] && break
	pass1=$(dialog --no-cancel --passwordbox "Passwords do not match or are not present.\n\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
done

export pass="$pass1"

IFS=' ' read -ra SIZE <<< $(cat psize)

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
    SIZE=(4 100);
fi

timedatectl set-ntp true

cat <<EOF | fdisk /dev/nvme0n1
o
n
p


+500M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF
partprobe

pacman --noconfirm --needed -S dosfstools amd-ucode

# Add encryption to /home
lukspass1=$(dialog --no-cancel --passwordbox "Enter a LUKS password." 10 60 3>&1 1>&2 2>&3 3>&1)
lukspass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)

while true; do
	[[ "$lukspass1" != "" && "$lukspass1" == "$lukspass2" ]] && break
	lukspass1=$(dialog --no-cancel --passwordbox "Passwords do not match or are not present.\n\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
	lukspass2=$(dialog --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
done
export lukspass="$lukspass1"
echo "$lukspass" | cryptsetup luksFormat /dev/nvme0n1p4
echo "$lukspass" | cryptsetup open /dev/nvme0n1p4 cryptroot


yes | mkfs.fat -F32 /dev/nvme0n1p1
yes | mkfs.ext4 /dev/nvme0n1p3
yes | mkfs.ext4 /dev/mapper/cryptroot

mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2

mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
mkdir -p /mnt/home
mount /dev/mapper/cryptroot /mnt/home

pacstrap /mnt linux linux-firmware base base-devel

genfstab -U /mnt >> /mnt/etc/fstab
cp tz.tmp /mnt/tzfinal.tmp
rm tz.tmp

### BEGIN
arch-chroot /mnt echo "root:$pass" | chpasswd

# Update mkinitcpio to use LUKS
sed -i 's/MODULES=()/MODULES=(ext4)/' /etc/mkinitcpio.conf
sed -i 's/filesystems/encrypt filesystems/' /etc/mkinitcpio.conf
mkinitcpio -p linux

TZuser=$(cat tzfinal.tmp)

ln -sf /usr/share/zoneinfo/$TZuser /etc/localtime

hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

pacman --noconfirm --needed -S networkmanager efibootmgr
systemctl enable NetworkManager
systemctl start NetworkManager

# Setup GRUB
pacman --noconfirm --needed -S grub efibootmgr
sed -i 's/#GRUB_ENABLE/GRUB_ENABLE/' /etc/default/grub
sed -i 's/quiet/quiet acpi_backlight=vendor/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=\/dev\/nvme0n1p4:cryptroot\"/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB /dev/nvme0n1
grub-mkconfig -o /boot/grub/grub.cfg



pacman --noconfirm --needed -S dialog
larbs() { curl -LO https://raw.githubusercontent.com/VitoMinheere/LARBS/master/larbs.sh && chmod +x larbs.sh && ./larbs.sh ;}
dialog --title "Install Vito's Rice" --yesno "This install script will easily let you access Vito's Auto-Rice Boostrapping Scripts (VARBS) which automatically install a full Arch Linux i3-gaps desktop environment.\n\nIf you'd like to install this, select yes, otherwise select no."  15 60 && larbs
### END


mv comp /mnt/etc/hostname

dialog --defaultno --title "Final Qs" --yesno "Reboot computer?"  5 30 && reboot
dialog --defaultno --title "Final Qs" --yesno "Return to chroot environment?"  6 30 && arch-chroot /mnt
clear
