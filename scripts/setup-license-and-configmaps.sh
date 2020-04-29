#!/bin/bash
# Helper script to pull the configuration directory from the Rosette Enterprise image and optionally
# configure various aspects of the Rosette Enterprise configuration (number of worker threads, if the server
# should be pre-warmed and where the usage tracking files should be placed). This script will optionally copy
# the license file to the ./config/rosapi directory so that it can be used as a configmap.
#

# which image to pull the configuration files from
IMAGE=
# the license file to use for the deployment
LICENSE_FILE=
# number of worker threads, default is 2, must be >=1
ROSETTE_WORKER_THREADS=2
# pre-warm the server on startup, default is false, valid values are true|false
ROSETTE_PRE_WARM=false
# where usage tracking files should be placed in the container
# note do not use a directory written to by all Pods
ROSETTE_USAGE_TRACKER_ROOT=/var/tmp

SRC_DIR=/rosette/server/launcher/config
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
DEST_DIR=${SCRIPT_DIR}/../rosent-pv/

function usage() {
    echo "$0 -i,--image image-to-pull [-w,--worker number worker threads] [-p,--prewarm prewarm, true or false] [-u,--usageroot usage tracker root directory, /var/tmp is default] [-l,--license full path to license file] [-h,--help prints this message]"
    echo ""
    exit 1
}

function sed_replace {
   if [[ "$OSTYPE" == "linux-gnu" ]] ; then
       sed -i $1 $2
   else
       sed -i '' $1 $2
   fi
}

while [ "$1" != "" ]; do
    case $1 in
        -i | --image )          shift
                                IMAGE=$1
                                ;;
        -w | --worker )         shift
                                ROSETTE_WORKER_THREADS=$1
                                ;;
        -p | --prewarm )        shift
                                ROSETTE_PRE_WARM=$1
                                ;;
        -u | --usageroot )      shift
                                ROSETTE_USAGE_TRACKER_ROOT=$1
                                ;;
        -l | --license )        shift
                                LICENSE_FILE=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ -z ${IMAGE} ]; then
    echo "Image is required"
    usage
fi

# copy the config files out of the image
#
${SCRIPT_DIR}/copy-files-from-image.sh ${IMAGE} ${SRC_DIR} ${DEST_DIR}
if [ $? -ne 0 ]; then
    printf "\033[0;31mError copying files from image ${IMAGE}\033[0m\n"
    exit 1
fi

WORKER_CFG_FILE="$DEST_DIR/config/com.basistech.ws.worker.cfg"
if [[ $ROSETTE_WORKER_THREADS -ge 1 ]] ; then
    if grep "^workerThreadCount=" "$WORKER_CFG_FILE" >/dev/null 2>&1 ; then
        sed_replace "s/^workerThreadCount=.*/workerThreadCount=$ROSETTE_WORKER_THREADS/g" "$WORKER_CFG_FILE"
    else
        echo "workerThreadCount=$ROSETTE_WORKER_THREADS" >> "$WORKER_CFG_FILE"
    fi
    echo "Updated ROSETTE_WORKER_THREADS to $ROSETTE_WORKER_THREADS"
fi

PRE_WARM="${ROSETTE_PRE_WARM}"
if [[ "$PRE_WARM" == "true" ]] ; then
    if grep "^warmUpWorker=" "$WORKER_CFG_FILE" >/dev/null 2>&1 ; then
        sed_replace "s/^warmUpWorker=.*/warmUpWorker=$PRE_WARM/g" "$WORKER_CFG_FILE"
    else
        echo "warmUpWorker=$PRE_WARM" >> "$WORKER_CFG_FILE"
    fi
    echo "Updated ROSETTE_PRE_WARM to $PRE_WARM"
fi

USAGE_CFG_FILE="$DEST_DIR/config/com.basistech.ws.local.usage.tracker.cfg"
if [ ! -z ${ROSETTE_USAGE_TRACKER_ROOT} ]; then
    if grep "^usage-tracker-root:" "$USAGE_CFG_FILE" >/dev/null 2>&1 ; then
        sed_replace "s#^usage-tracker-root:.*#usage-tracker-root:$ROSETTE_USAGE_TRACKER_ROOT#g" "$USAGE_CFG_FILE"
    else
        echo -e "\nusage-tracker-root:$ROSETTE_USAGE_TRACKER_ROOT" >> "$USAGE_CFG_FILE"
    fi
    if grep "^enabled:" "$USAGE_CFG_FILE" >/dev/null 2>&1 ; then
        sed_replace "s/^enabled:.*/enabled:true/g" "$USAGE_CFG_FILE"
    fi
    echo "Updated ROSETTE_USAGE_TRACKER_ROOT to $ROSETTE_USAGE_TRACKER_ROOT"
else
    if grep "^usage-tracker-root:" "$USAGE_CFG_FILE" >/dev/null 2>&1 ; then
        sed_replace "s#^usage-tracker-root:.*#\#usage-tracker-root:#g" "$USAGE_CFG_FILE"
    fi
    echo "Reset ROSETTE_USAGE_TRACKER_ROOT. If enabled, metering is written to config directory by default."
fi

if [ ! -z ${LICENSE_FILE} ]; then
    cp -v "${LICENSE_FILE}" $DEST_DIR/config/rosapi/
    if [ $? -ne 0 ]; then
        printf "\033[0;31mError copying rosette-license.xml, please correct the error and try again\033[0m\n"
    else    
        echo "Copy successful"
    fi
else
    printf "\033[0;31mCopy rosette-license.xml to $DEST_DIR/config/rosapi/ before deploying the chart!\033[0m\n"
fi