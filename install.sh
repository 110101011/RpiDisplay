#!/usr/bin/env bash

interactive=0
screensize=0
graphical=0
rotation=0

usage() {
	printf "Usage:
		-i | --interactive: 	Run in interactive mode
		-s | --screensize: 	Specify screensize i.e. -s 35
		-g | --graphical:	Install with X-server support
		-r | --rotation:	Screen rotation (0, 270)
		-h | --help:		Print this screen\n\n"
	}

while [ "$1" != "" ];
do
	case $1 in
		-i | --interactive )	interactive=1
					;;
		-s | --screensize )	shift
					screensize="$1"
					;;
		-g | --graphical )	graphical=1
					;;
		-r | --rotation )	shift
					rotation="$1"
					;;
		-h | --help )		usage
					exit
					;;
		* )			usage
					exit 1
	esac
	shift
done

if [ $interactive == 1 ];
then
	# TODO: Check for all variables
	# TODO: Create nicer layout
	printf "Choose Screensize:\n"
	printf "28 - 2.8 Inch screen\n"
	printf "35 - 3.5 Inch screen\n"
	read screensize

	printf "Do you use an X-server?\n"
	read graphical

	printf "Rotation of the screen\n"
	read rotation

	printf "\nConfiguration:\n"
	printf "Screensize = "$screensize"\n"
	printf "X-server support = "$graphical"\n"
	printf "Screen rotation = "$rotation"\n"
	read correct

fi

# Check screensize for screensize and copy the correct overlay
# TODO: Add support for more screensizes
if [ $screensize == 35 ];
then
	printf "Copying the boot overlay for 3.5 inch screen... "
	sudo cp ./overlays/tft35a-overlay.dtb /boot/overlays/tft35a.dtbo
	printf "Done\n"
else
	printf "Screensize not supported...\n"
fi

# Enable SPI in /boot/confing.txt
printf "Enabling SPI interface... "
sudo sed -i 's/#dtparam=spi=on/dtparam=spi=on/' /boot/config.txt
printf "Done\n"

# Force HDMI hotplug to use non HDMI screen
printf "Force HDMI hotplug for SPI screen detection... "
sudo sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/' /boot/config.txt
printf "Done\n"

# Append overlay and add rotation to /boot/config.txt
if [ $rotation == 0 ]
then
	printf "Adding overlay without rotation... "
	sudo sed -i -e '$adtoverlay=tft'$screensize'a' /boot/config.txt
	printf "Done\n"
else
	printf "Adding overlay with rotation... "
	sudo sed -i -e '$adtoverlay=tft'$screensize'a:rotate='$rotation /boot/config.txt
	printf "Done\n"
fi

# Append fbcon=map:10 to cmdline.txt (TODO: Not sure if needed!)
printf "Adding fbcon=map:10 to cmdline.txt... "
sudo sed -i 's/115200/& fbcon=map:10/' cmdline.txt
printf "Done\n"

# At this stage where done if there there's no X-Server installed
if [ $graphical == 0 ]
then
	printf "Please reboot your Raspberry Pi to complete te setup"
	exit 0
fi

# Add calibration data for Xorg
printf "Copying calibration data... "
sudo mkdir /etc/X11/xorg.conf.d
# TODO: Check screensize to copy correct data
sudo cp -rf ./conf/99-calibration.conf-35-$rotation /etc/X11/xorg.conf.d/99-calibration.conf
sudo cp -rf ./conf/99-fbturbo.conf /usr/share/X11/xorg.conf.d/
printf "Done\n"

# Enable multiple input devices
printf "Installing evdev to enable multiple input devices... "
sudo apt install xserver-xorg-input-evdev
# TODO: Not sure if needed!
sudo cp -rf /usr/share/X11/xorg.conf.d/{10,45}-evdev.conf
printf "Done\n\n"

printf "Please reboot your Raspberry Pi to complete the setup."


