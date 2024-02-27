# Copyright 2023 Basis Technology Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash
BASE_DIR="$( cd "$( dirname "$0" )" && pwd )"

# This script assumes the following:

# Volumes
# /rosette/server/roots
# /rosette/server/launcher/config
# /rosette/server/conf
#

function usage() {
    echo ""
    echo -e "usage $0 -r rosette image -d base directory holding the volumes to mount"
    echo -e "\t-r the Rosette Server container image to use e.g. rosette/server-enterprise:1.27.0"
    echo -e "\t-d the base directory holding the volumes to mount e.g. ./"
    echo -e "\tThis script assumes the following directories exist:"
    echo -e "\t\t{base directory}/roots"
    echo -e "\t\t{base directory}/config"
    echo -e "\t\t{base directory}/config/rosapi"
    echo -e "\t\t{base directory}/conf"
    echo ""
    echo "Please see ${BASE_DIR}/../README.md for information on how to extract the roots and configuration"
    echo ""
    exit 0
}

VOL_DIR=""
ROSETTE_SERVER_IMAGE=""
while [ "$#" -gt 0 ]; do
  case $1 in
    -r)
      shift
      ROSETTE_SERVER_IMAGE=$1
      shift
      ;;
    -d)
      shift
      VOL_DIR=$1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if [[ $ROSETTE_SERVER_IMAGE == "" ]]; then
    echo "[ERROR] No Rosette Server image given"
    usage
fi

if [[ $VOL_DIR == "" ]]; then
    echo "[ERROR] No base directory given"
    usage
fi

if [[ ! -d ${VOL_DIR}/roots ]] || [[ ! -d ${VOL_DIR}/config ]] || [[ ! -d ${VOL_DIR}/config/rosapi ]] || [[ ! -d ${VOL_DIR}/conf ]]; then 
    echo "This script assumes ${VOL_DIR}/roots ${VOL_DIR}/config ${VOL_DIR}/config/rosapi ${VOL_DIR}/conf have been created."
    echo "Please see ${BASE_DIR}/../README.md for information on how to extract the roots and configuration"
    exit 1
fi

# Config is rw only if usage is enabled (default) and logging to the config directory (default), refer to ../rosette-server/README.md
CONTAINER=$(docker run -d -p 8181:8181 -v ${VOL_DIR}/config:/rosette/server/launcher/config:rw -v ${VOL_DIR}/roots:/rosette/server/roots:ro  -v ${VOL_DIR}/conf:/rosette/server/conf:ro ${ROSETTE_SERVER_IMAGE} bash -c '/rosette/server/bin/launch.sh console')

echo "Watch logs: docker logs $CONTAINER -f"
echo "When done testing: docker stop $CONTAINER"
echo "When done testing: docker rm $CONTAINER"
echo "Please wait approximately 40s and run: curl http://localhost:8181/rest/v1/ping to confirm Rosette Server has started."


