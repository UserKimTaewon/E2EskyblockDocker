#!/bin/bash

#### Minecraft-Forge Server install/launcher script
#### Linux Version
####
#### Created by: Dijkstra
#### Mascot: Ordinator
####
#### Originally created for use in "All The Mods" modpacks
#### NO OFFICIAL AFFILIATION WITH MOJANG OR FORGE
####
#### This script will fetch the appropriate forge installer
#### and run it to install forge AND fetch Minecraft (from Mojang)
#### If Forge and Minecraft are already installed it will skip
#### download/install and launch server directly (with
#### auto-restart-after-crash logic as well)
####
#### Make sure this is running as BASH
#### You might need to chmod +x before executing
####
#### IF THERE ARE ANY ISSUES
#### Please make a report on the AllTheMods github:
#### https://github.com/whatthedrunk/allthemods/issues
#### with the contents of [serverstart.log] and [installer.log]
####
#### or come find us on Discord: https://discord.gg/FdFDVWb
####


#For Server Owners

	
#
#
#
#
#
#
#
# Internal scripty stuff from here on out
# No lines intended to be edited past here
#
#
#
#
#
# Make sure users aren't trying to run script via sh directly (won't work)

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

if [ ! "$BASH_VERSION" ] ; then
    echo "Please do not use sh to run this script ($0). Use bash instead (or execute it directly)" 1>&2
    exit 1
fi

# routine to handle Forge/server install
install_server(){
	echo "Starting install of Forge/Minecraft server binaries"
	echo "DEBUG: Starting install of Forge/Minecraft server binaries"
	if [ -f installer.jar ]; then
		echo "DEBUG: installer.jar found in current directory, skipping install installer.jar"
	else
		if [ "${FORGEURL}" = "DISABLE" ]; then
			export URL="http://files.minecraftforge.net/maven/net/minecraftforge/forge/${MCVER}-${FORGEVER}/forge-${MCVER}-${FORGEVER}-installer.jar"
		else
			export URL="${FORGEURL}"
		fi
		echo $URL
		which wget >> /dev/null
		if [ $? -eq 0 ]; then
			echo "DEBUG: (wget) Downloading ${URL}" >>serverstart.log 2>&1
			wget -O installer.jar "${URL}" >>serverstart.log 2>&1
		else
			which curl >> /dev/null
			if [ $? -eq 0 ]; then
				echo "DEBUG: (curl) Downloading ${URL}" >>serverstart.log 2>&1
				curl -o installer.jar "${URL}" >>serverstart.log 2>&1
			else
				echo "Neither wget or curl were found on your system. Please install one and try again"
				echo "ERROR: Neither wget or curl were found" >>serverstart.log 2>&1
			fi
		fi
	fi

	if [ ! -f installer.jar ]; then
		echo "Forge installer did not download"
		echo "ERROR: Forge installer did not download"
		exit 1
	else
		echo "Moving unneeded files/folders to ./DELETEME"
		echo "INFO: Moving unneeded files/folders to ./DELETEME"
		rm -rf ./DELETEME
		mv -f ./asm ./DELETEME
		mv -f ./libraries ./DELETEME
		mv -f ./llibrary ./DELETEME
		mv -f ./minecraft_server*.jar ./DELETEME
		mv -f ./forge*.jar ./DELETEME
		mv -f ./OpenComputersMod*lua* ./DELETEME
		rm -rf ./DELETEME
		echo "Installing Forge Server, please wait..."
		echo "INFO: Installing Forge Server"
		java -jar installer.jar --installServer
		echo "Deleting Forge installer (no longer needed)"
		echo "INFO: Deleting installer.jar"
		rm -rf installer.jar 
	fi
}



# routine for basic directory checks
check_dir(){
	echo "DEBUG: Current directory is " $(pwd)
	if [ "$(pwd)" = "/tmp" ] || [ "$(pwd)" = "/var/tmp" ]; then
		echo "Current directory appears to be TMP"
		echo "WARN: Current DIR is TEMP" 
		if [ ${RUN_FROM_BAD_FOLDER} -eq 0 ]; then
			echo "ERROR: Stopping due to bad folder (TMP)"
			echo "RUN_FROM_BAD_FOLDER setting is off, exiting script"
			exit 0
		else
			echo "WARN: Bad folder (TMP) but continuing anyway"
			echo "Bypassing cd=temp halt per script settings"
		fi
	fi

	if [ ! -r . ] || [ ! -w . ]; then
	echo "WARN: Not full R/W access on current directory"
	echo "You do not have full R/W access to current directory"
		if [ ${RUN_FROM_BAD_FOLDER} -eq 0 ]; then
		echo "ERROR: Stopping due to bad folder (R/W access)"
		echo "RUN_FROM_BAD_FOLDER setting is off, exiting script"
		exit 0
		else
		echo "WARN: Bad folder (R/W) cut continuing anyway"
		echo "Bypassing no R/W halt (per script settings)"
		fi
	fi
}

# routine to make sure necessary binaries are found
check_binaries(){
	if [ ! -f ${FORGE_JAR} ] ; then
		echo "WARN: ${FORGE_JAR} not found"  >>serverstart.log 2>&1
		echo "Required files not found, need to install Forge"
		install_server
	fi
	if [ ! -f ./minecraft_server.${MCVER}.jar ] ; then
		echo "WARN: minecraft_server.${MCVER}.jar not found" >>serverstart.log 2>&1
		echo "Required files not found, need to install Forge"
		install_server
	fi
	if [ ! -d ./libraries ] ; then
		echo "WARN: library directory not found" >>serverstart.log 2>&1
		echo "Required files not found, need to install Forge"
		install_server
	fi
}

read_config(){
	while read -r line || [[ -n "$line" ]] ; do
   		if echo $line | grep -F = &>/dev/null; then
   			if [[ ${str:0:1} != "#" ]] ; then
      			name=$(echo "$line" | cut -d '=' -f 1)
      			val=$(echo "${line}" | cut -d '=' -f 2-)
      			eval "export ${name}='${val%?}'"
      		fi
   		fi
	done < settings.cfg 

}

eula(){
	if [ ! -f eula.txt ]; then
		echo "Could not find eula.txt, generating it."
		echo "# EULA accepted on $(date)" > eula.txt && \
		echo "eula=true" >> eula.txt
	fi
	if grep -Fxq "eula=false" eula.txt; then
		echo "Could not find 'eula=true' in 'eula.txt'"
		echo "Setting 'eula=true'"
		sed -i "/eula=false/ c eula=true" eula.txt
	fi
}

read_config

# Script/batch starts here...

# init log file and dump basic info
echo "INFO: Starting script at" $(date -u +%Y-%m-%d_%H:%M:%S) >serverstart.log 2>&1
echo "DEBUG: Dumping starting variables: "
echo "DEBUG: MAX_RAM=$MAX_RAM"
echo "DEBUG: JAVA_ARGS=$JAVA_ARGS"
echo "DEBUG: CRASH_COUNT=$CRASH_COUNT"
echo "DEBUG: RUN_FROM_BAD_FOLDER=$RUN_FROM_BAD_FOLDER"
echo "DEBUG: IGNORE_OFFLINE=$IGNORE_OFFLINE"
echo "DEBUG: MCVER=$MCVER"
echo "DEBUG: FORGEVER=$FORGEVER"
echo "DEBUG: FORGEURL=$FORGEURL"
echo "DEBUG: Basic System Info: " $(uname -a)
if [ "$machine" = "Mac" ] 
then
  echo "DEBUG: Total RAM estimate: " $(sysctl hw.memsize | awk 'BEGIN {total = 1} {if (NR == 1 || NR == 3) total *=$NF} END {print total / 1024 / 1024" MB"}')
else
  echo "DEBUG: Total RAM estimate: " $(getconf -a | grep PAGES | awk 'BEGIN {total = 1} {if (NR == 1 || NR == 3) total *=$NF} END {print total / 1024 / 1024" MB"}')
fi
echo "DEBUG: Java Version info: " $(java -version)
echo "DEBUG: Dumping current directory listing "
ls -s1h

check_dir
check_binaries
eula
