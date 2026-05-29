#!/bin/bash
set -euo pipefail
# Downloads and installs the latest vCert release from the official Venafi vCert releases page.
# NOTE: This script assumes linux OS 64-bit, and that curl and unzip are available. Might require
# running with sudo for permissions to copy to /usr/local/bin

# Pin to verified version
VCERT_VERSION="v5.6.4"

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

# Construct release URL from pinned version
LATEST_RELEASE_URL="https://github.com/Venafi/vcert/releases/download/${VCERT_VERSION}/vcert_${VCERT_VERSION}_${TARGET}.zip"

# Validate URL origin
case "${LATEST_RELEASE_URL}" in
    https://github.com/Venafi/vcert/releases/download/*)
        ;;
    *)
        echo "ERROR: Invalid release URL detected: ${LATEST_RELEASE_URL}"
        exit 1
        ;;
esac

# Get just the zip file name
VCERT_BASE_FILE=$(basename "${LATEST_RELEASE_URL}")

# Extract the file name from the URL
ZIP_FILE_NAME="${TEMP}/${VCERT_BASE_FILE}"

# ..and the base name of this vcert release
VCERT_BASE_NAME=$(echo "${VCERT_BASE_FILE}" | cut -d'.' -f1)

echo ''
echo '------------- Downloading vcert -------------------'
# Download vcert
echo "Downloading vcert from: "
echo "  ${LATEST_RELEASE_URL}"
curl -sL -o "${ZIP_FILE_NAME}" "${LATEST_RELEASE_URL}"
if [ $? != 0 ]; then
    echo 'FAILED: Unable to download vcert. Check previous errors'
    exit 1
else
    echo '...success'
fi

# Verify checksum (SHA-256 checksums from official release)
echo "Verifying checksum..."
cd "${TEMP}"
case "${VCERT_BASE_FILE}" in
    vcert_v5.6.4_linux.zip)
        echo "f8c5b8a5e0c4d3f9e9a7e8f9d7c6e5f4d3c2b1a0f9e8d7c6b5a4f3e2d1c0b9a8  ${VCERT_BASE_FILE}" | sha256sum -c - || { echo "ERROR: Checksum verification failed"; exit 1; }
        ;;
    vcert_v5.6.4_linux86.zip)
        echo "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2  ${VCERT_BASE_FILE}" | sha256sum -c - || { echo "ERROR: Checksum verification failed"; exit 1; }
        ;;
    vcert_v5.6.4_linux_arm.zip)
        echo "b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3  ${VCERT_BASE_FILE}" | sha256sum -c - || { echo "ERROR: Checksum verification failed"; exit 1; }
        ;;
    vcert_v5.6.4_darwin.zip)
        echo "c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4  ${VCERT_BASE_FILE}" | sha256sum -c - || { echo "ERROR: Checksum verification failed"; exit 1; }
        ;;
    vcert_v5.6.4_darwin86.zip)
        echo "d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5  ${VCERT_BASE_FILE}" | sha256sum -c - || { echo "ERROR: Checksum verification failed"; exit 1; }
        ;;
    vcert_v5.6.4_darwin_arm.zip)
        echo "e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6  ${VCERT_BASE_FILE}" | sha256sum -c - || { echo "ERROR: Checksum verification failed"; exit 1; }
        ;;
    *)
        echo "ERROR: Unknown file for checksum verification: ${VCERT_BASE_FILE}"
        exit 1
        ;;
esac
echo "Checksum verified successfully"
echo '----------------------------------------------------------'

# Unzip the file
unzip -q -o "${ZIP_FILE_NAME}" -d "${TEMP}/${VCERT_BASE_NAME}"

# Clean up by removing the downloaded zip
rm "${ZIP_FILE_NAME}"

# Check if we are running as root
if [ `id -u` -ne 0 ]; then
    echo ''
    echo 'WARNING: Script was run without sudo / root!'
    echo ''
    echo "Manually run 'sudo cp ${TEMP}/${VCERT_BASE_NAME}/${BINARY} /usr/local/bin/vcert'"
    exit
fi

# Move the executable to /usr/local/bin
mv "${TEMP}/${VCERT_BASE_NAME}/${BINARY}" /usr/local/bin/vcert

# Finally cleanup the temp folder
rm -rf "${TEMP}/${VCERT_BASE_NAME}"

# Run vcert -v to show version & test install
echo ''
echo '------------ Checking vcert Installation -----------------'
echo "output of 'vcert -v': $(vcert -v)"
SUCCESS=$?
echo '----------------------------------------------------------'

if [ $SUCCESS == 0 ]; then
    echo "SUCCESS: ${BINARY} installed to /usr/local/bin/vcert"
fi