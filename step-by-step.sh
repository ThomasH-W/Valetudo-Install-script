#!/bin/bash
#
# file: step-by-step.sh
# date: 2026-04-04 v2
#
# Valetudo install for Roborock S7 pro ultra
# - https://valetudo.cloud/pages/installation/roborock.html#fel
#
# Install sunxi
# - sudo apt-get -y install sunxi-tools
#
# To build the firmware, head over to the Dustbuilder 
# - https://builder.dontvacuum.me/
# - Download and Extract files 
# - Update variables below:
#
FEL_DIR="roborock.vacuum.a62_0184_fel"
KEY_FILE="ssh-keys/YourKeyFile.id_rsa"
ROOTED_FW_FILE="roborock.vacuum.a62_0184_fw.tar.gz"
VALETUDO_FW_FILE="valetudo-armv7-lowmem.upx"

# ----------------------------------------- no update below 
ROBOT_IP="192.168.8.1"

RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# echo -e "I ${RED}love${NC} Stack Overflow"

check_file() {
	FILE=$1
	if [ ! -f "$FILE" ]; then
    	  echo -e "${RED}### ERROR> $FILE does not exist.${NC}"
    	  read -p "Press Enter to continue"
    	else
    	  echo "$FILE ok"
	fi
}

check_files() {
  check_file $FEL_DIR/run.sh
  check_file $ROOTED_FW_FILE
  check_file $KEY_FILE
  check_file $VALETUDO_FW_FILE
}

check_sunxi-fel(){
	which sunxi-fel
	result=$?
	if [ $result -gt 0 ]; then
    	echo -e "${RED}### ERROR> sunxi-fel does not exist.${NC}"
    	echo "try: sudo apt-get -y install sunxi-tools"
    	read -p "Press Enter to continue"
	fi
}

ping_robot() {
	echo "ping robot"
	ping -c 1 -t 5 $ROBOT_IP
	result=$?
	if [ $result -gt 0 ]; then
    	echo -e "${RED}### ERROR> $ROBOT_IP did not reply to ping${NC}"
    	read -p "Press Enter to continue"
	fi
	echo ""
}

press_enter() {
	read -p "----------------------- Press Enter to continue"
	echo ""
}

echo "----------------------------------- $0"

echo "----------------------- Prep: check files"
check_files
check_sunxi-fel


echo "----------------------- Step 1 - Enter Flash Mode"
echo "> make sure robot is fully charged"
echo "> connect USB cable"
echo "> connect battery - but do NOT turn on"
echo "> connect TPA17 to GND (e.g. SH1)"
press_enter
echo "> press power button for 3 seconds"
sleep 3s
echo "> keep TPA17 low another 5 seconds"
sleep 5s

# MacOS: brew install lsusb
echo "> you should see a device like:"
echo "> Bus 001 Device 014: ID 1f3a:efe8 Allwinner Technology sunxi SoC OTG connector in FEL/flashing mode"
echo -e "${BLUE}lsusb${NC}"
lsusb | grep "FEL"
press_enter

echo "----------------------- Step 2 - load live linux system"
echo -e "${BLUE}cd $FEL_DIR/${NC}"
echo -e "${BLUE}sudo ./run.sh${NC}"
echo -e "${BLUE}cd ..${NC}"
cd $FEL_DIR && pwd && sudo ./run.sh ; cd ".." && pwd
echo "> Watch the robots’ LEDs. It should reboot after a while."
echo "> It won’t play any sounds as the speaker will likely be unplugged."
echo "> Connect to notebook to WiFi AP: e.g. roborock-vacuum-s5e_miapFDD5"
echo "> If SSID is not visible: Press and hold the two outer buttons until"
echo "> you see the Wi-Fi LED change"
press_enter

echo "----------------------- Step 3 - backup nand on robot via ssh"
ping_robot
echo "> backup flash partitions nandb + nandk"
echo -e "${BLUE}ssh -i $KEY_FILE -o ConnectTimeout=10 root@192.168.8.1${NC}"
echo -e "${YELLOW}ssh> dd if=/dev/nandb | gzip > /tmp/nandb.img.gz${NC}"
echo -e "${YELLOW}ssh> dd if=/dev/nandk | gzip > /tmp/nandk.img.gz${NC}"
ssh -i $KEY_FILE -o ConnectTimeout=5 root@192.168.8.1 'dd if=/dev/nandb | gzip > /tmp/nandb.img.gz; dd if=/dev/nandk | gzip > /tmp/nandk.img.gz'

press_enter

echo "----------------------- Step 4 - new terminal 2"
echo "> Disconnect or open a second terminal and pull those backups to your laptop "
ping_robot
echo -e "${BLUE}scp -O -i $KEY_FILE root@192.168.8.1:/tmp/nand* .${NC}"
# scp -O -i $KEY_FILE root@192.168.8.1:/tmp/nand* .${NC}
press_enter

echo "----------------------- Step 5 - terminal 1: remove log files"
echo "> remove logfiles to free up space"
echo -e "${YELLOW}t1> rm -rf /mnt/data/rockrobo/rrlog/*${NC}"
press_enter

echo "> copy full rooted firmware image"
ping_robot
# echo "scp -O -i ~/.ssh/your_keyfile Downloads/roborock.vacuum.s5e_1566_fw.tar.gz root@192.168.8.1:/mnt/data/"
echo -e "${BLUE}scp -O -i $KEY_FILE $ROOTED_FW_FILE root@192.168.8.1:/mnt/data/${NC}"
# scp -O -i $KEY_FILE $ROOTED_FW_FILE root@192.168.8.1:/mnt/data/${NC}
press_enter


echo "----------------------- Step 6 - terminal 1: install firmware"
echo "> install firmware - part 1"
echo -e "${YELLOW}t1> cd /mnt/data/ && tar xvzf $ROOTED_FW_FILE && ./install.sh${NC}"
echo -e "${YELLOW}t1> reboot${NC}"
press_enter

echo "----------------------- Step 7 - terminal 1: install firmware"
echo "> connect WiFi again"
echo "> install firmware - part 2"
echo -e "${YELLOW}t1> cd /mnt/data/ && tar xvzf $ROOTED_FW_FILE && ./install.sh${NC}"
echo -e "${YELLOW}t1> reboot${NC}"
press_enter

echo "----------------------- Step 8 - push Valetudo firmware"
echo "> connect WiFi again"
echo "> copy firmware"
echo -e "${BLUE}scp -O -i $KEY_FILE $VALETUDO_FW_FILE root@192.168.8.1:/mnt/data/valetudo${NC}"
scp -O -i $KEY_FILE $VALETUDO_FW_FILE root@192.168.8.1:/mnt/data/valetudo${NC}
press_enter

echo "----------------------- Step 9 - terminal 1: cleanup"
echo "> clean up the installer files and setup valetudo to autostart on boot:"
echo -e "${YELLOW}t1> cd /mnt/data/ && rm roborock.vacuum.*.gz boot.img firmware.md5sum rootfs.img install.sh${NC}"
echo -e "${YELLOW}t1> cp /root/_root.sh.tpl /mnt/reserve/_root.sh${NC}"
echo -e "${YELLOW}t1> chmod +x /mnt/reserve/_root.sh /mnt/data/valetudo${NC}"
echo -e "${YELLOW}t1> reboot${NC}"
press_enter

echo "----------------------- Step 10: check firmware"
echo "> connect WiFi again"
echo "> wait for 1 or 2 min"
echo "> open: http://192.168.8.1."
press_enter

echo "----------------------- Step 11 - assemble and follow guide"
echo '>open: https://valetudo.cloud/pages/general/getting-started.html#using-valetudo'
echo ""
