#!/bin/bash
# Downloads and installs the latest vCert release from the official Venafi vCert releases page.
# NOTE: This script assumes linux OS 64-bit, and that curl and unzip are available. Might require
# running with sudo for permissions to copy to /usr/local/bin

# Use /tmp for temp directory
TEMP=/tmp

# Determine OS (this script should work on MacOS & Linux)
OS='UNKNOWN'
case $OSTYPE in
    darwin*) OS="darwin";;  # MacOS
    linux*) OS="linux";;    # Linux
esac

if [ "$OS" == "UNKNOWN" ]; then
    echo "ERROR: Running on unsupported OS. Linux/MacOS required."
    exit -1
fi


# Determine processor architecture and set TARGET download
TARGET=''
BINARY='vcert'
ARCH=$(uname -m)
case $ARCH in
    arm*) TARGET="${OS}_arm"; BINARY="${BINARY}_arm";;
    aarch64) TARGET="${OS}_arm"; BINARY="${BINARY}_arm";;
    x86) TARGET="${OS}86"; BINARY="${BINARY}86";;
    x86_64) TARGET="${OS}";;
    i686) TARGET="${OS}86"; BINARY="${BINARY}86";;
    i386) TARGET="${OS}86"; BINARY="${BINARY}86";;
esac

if [ ${TARGET} == '' ]; then
    echo "ERROR: Unsupported OS / Architecture: ${OS} / ${ARCH}"
    exit -2
fi

# Get the latest release URL using GitHub API
LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/Venafi/vcert/releases/latest | grep "browser_download_url.*_${TARGET}.zip" | cut -d : -f 2,3 | tr -d \")

# Get just the zip file name
VCERT_BASE_FILE=$(basename ${LATEST_RELEASE_URL})

# Extract the file name from the URL
ZIP_FILE_NAME=${TEMP}/${VCERT_BASE_FILE}

# ..and the base name of this vcert release
VCERT_BASE_NAME=$(echo ${VCERT_BASE_FILE} | cut -d'.' -f1)

echo ''
echo '------------- Downloading latest vcert -------------------'
# Download vcert
echo "Downloading vcert from: "
echo "  ${LATEST_RELEASE_URL}"
curl -sL -o ${ZIP_FILE_NAME} ${LATEST_RELEASE_URL}
if [ $? != 0 ]; then
    echo 'FAILED: Unable to download vcert. Check previous errors'
else
    echo '...success'
fi
echo '----------------------------------------------------------'

# Unzip the file
unzip -q -o ${ZIP_FILE_NAME} -d ${TEMP}/${VCERT_BASE_NAME}

# Clean up by removing the downloaded zip
rm $ZIP_FILE_NAME

# Check if we are running as root
if [ `id -u` -ne 0 ]; then
    echo ''
    echo 'WARNING: Script was run without sudo / root!'
    echo ''
    echo "Manually run 'sudo cp ${TEMP}/${VCERT_BASE_NAME}/${BINARY} /usr/local/bin/vcert'"
    exit
fi

# Move the executable to /usr/local/bin
mv ${TEMP}/${VCERT_BASE_NAME}/${BINARY} /usr/local/bin/vcert

# Finally cleanup the temp folder
rm -rf ${TEMP}/${VCERT_BASE_NAME}

# Run vcert -v to show version & test install
echo ''
echo '------------ Checking vcert Installation -----------------'
echo "output of 'vcert -v': $(vcert -v)"
SUCCESS=$?
echo '----------------------------------------------------------'

if [ $SUCCESS == 0 ]; then
    echo "SUCCESS: ${BINARY} installed to /usr/local/bin/vcert"
fi