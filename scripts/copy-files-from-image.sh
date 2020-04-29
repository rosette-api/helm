#!/bin/bash

# Helper script to copy files or directories from a Docker image to the local file system.
# It is used in the case of the rosent-pv project to copy the config directory from the
# Rosette Enterprise image to the ./rosent-pv directory so that the Helm template can generate 
# the required configmaps for the deployment.
#
# Usage: ./copy-files-from-image.sh image source destination
#       image: the Docker image to pull the 'source' from
#       source: source file or directory to copy
#       destination: where to copy 'source' to

image=$1
source=$2
destination=$3

if [ $# -ne 3 ]; then
    echo "Usage:"
    echo "$0 image source destination"
    echo ""
    echo "Example:"
    echo "$0 rosette/server-enterprise:1.15.1 /rosette/server/launcher/config ./rosent-pv/config"
    echo ""
    echo "Notes:" 
    echo -e "\t The destination directory will be created."
    echo -e "\t If a directory is specified then the directory and all subdirectories will be copied."
    exit 1
fi

if [ ! -d "${destination}" ] 
then
    echo "Directory ${destination} does not exist, creating." 
    mkdir -p "${destination}"
    if [ $? -ne 0 ]; then
        echo "Failed to create directory, exiting"
        exit 1
    fi
fi

containerId=$(docker create $image)
if [[ $containerId == "" ]]; then
    echo "Could not create ${image} exiting"
    exit 1
fi

docker cp $containerId:$source $destination
if [ $? -ne 0 ]; then
    echo "Copy failed from ${source} to ${destination}"
    exit 1
fi

removed=$(docker rm $containerId)
if [[ $removed != $containerId ]]; then
    echo "Could not remove $containerId"
    exit 1
fi
