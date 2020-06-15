#!/bin/bash

# This is a helper script to pull the roots required for the k8s deployment. 
# This script will read the `language.properties` file to determine which languages 
# for REX and TVEC to pull. You must update this file to correspond to your 
# licensed languages. Then running the `pull-roots.sh` script will parse 
# the `../rosent-pv/config/com.basistech.ws.worker.cfg` file to determine the 
# roots and versions that should be pulled. The docker images will be pulled 
# and the `.tar.gz` containing the root will be extracted to the destination 
# directory provided. Once extracted the `.tar.gz` files can be uploaded 
# to the NFS server. 

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
WORKER_CFG="$SCRIPT_DIR/../rosent-pv/config/com.basistech.ws.worker.cfg"
PROPERTIES_FILE="$SCRIPT_DIR/language.properties"

function usage() {
    printf "Usage: %s output directory for roots\n" $0 
    exit 1
}

# 1==file to read, 2==key, 3==value if key not found
function read_key {

    if [[ $1 == "" ]]; then
        log ERROR "No file given"
        exit 1
    fi
    local _KEY=$2
    if [[ $_KEY == "" ]]; then
        log ERROR "No key given"
        exit 1
    fi

    local _DEFAULT_RESPONSE=$3

    while IFS= read -r line
    do
        if [[ "$line" =~ ^$_KEY= ]]; then
            echo "${line#*=}"
            return
        fi
    done < "$1"
    echo "$_DEFAULT_RESPONSE"
}

if [ ! -f "$WORKER_CFG" ]; then
    printf "\033[0;31m[ERROR] $WORKER_CFG does not exist, pull config first.\033[0m\n"
    exit 1
fi

if [[ ! -f "$PROPERTIES_FILE" ]]; then
    printf "\033[0;31m[ERROR] $PROPERTIES_FILE does not exist, exiting.\033[0m\n"
    exit 1
fi

if [ $# -ne 1 ]; then
    printf "\033[0;31m[ERROR] Output directory not specified, exiting.\033[0m\n"
    usage 
fi

DEST=$1
if [[ ! -d "$DEST" ]]; then
    printf "\033[0;31m[ERROR] Output directory does not exist, exiting.\033[0m\n"
    usage 
else
    printf "Writing roots to $DEST\n"
fi

REX_LANGS=$(read_key "$PROPERTIES_FILE" "REX_LANGS" "root")
REX_LANGS=$REX_LANGS",root"
REX_LANGS=$(echo $REX_LANGS | awk '{print tolower($0)}')

TVEC_LANGS=$(read_key "$PROPERTIES_FILE" "TVEC_LANGS" "none")
TVEC_LANGS=$(echo $TVEC_LANGS | awk '{print tolower($0)}')

for root in $(grep rosapi.roots $WORKER_CFG | sed 's/\// /g' | awk '{print $2" "$3}' | sort -u | awk '{print "rosette/root-"$1":"$2}'); do
    root=$(echo $root | awk '{print tolower($0)}')

    if [[ $root == *"-rex:"* ]]; then
        original=$root
        for lang in $(echo $REX_LANGS | sed "s/,/ /g")
        do
            root=$(echo $original | sed "s/-rex:/-rex-${lang}:/g")
            ${SCRIPT_DIR}/copy-files-from-image.sh $root /data/root $DEST
        done
    elif [[ $root == *"-tvec"* ]]; then
        original=$root
        for lang in $(echo $TVEC_LANGS | sed "s/,/ /g")
        do
            if [[ $lang != "none" ]]; then
                root=$(echo $original | sed "s/-tvec:/-tvec-${lang}:/g")
                ${SCRIPT_DIR}/copy-files-from-image.sh $root /data/root $DEST
            fi
        done
    else
        ${SCRIPT_DIR}/copy-files-from-image.sh $root /data/root $DEST
    fi
done

