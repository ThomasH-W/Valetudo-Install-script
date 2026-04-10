# Valetudo-Install-script
Valetudo Install script

Reference: https://valetudo.cloud/pages/installation/roborock.html#fel

# Purpose
The tool did help myself to just look at the next step i/o of reading the whole instruction again and again to find the required action.
In addition variables are defined to reference the files so the required commmands can be applied by copy and paste w/o further changes.

# Preparation
Install sunxi
 - sudo apt-get -y install sunxi-tools

To build the firmware, head over to the Dustbuilder 
 - https://builder.dontvacuum.me/

Download and Extract files 

Update variables below in the shell script:
 - FEL_DIR="roborock.vacuum.a62_0184_fel"
 - KEY_FILE="ssh-keys/YourKeyFile.id_rsa"
 - ROOTED_FW_FILE="roborock.vacuum.a62_0184_fw.tar.gz"
 - VALETUDO_FW_FILE="valetudo-armv7-lowmem.upx"
