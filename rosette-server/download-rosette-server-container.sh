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
source ${BASE_DIR}/scripts/utils.sh

function usage() {
    msg "usage $0 -r rosette image"
    msg "\t-r the Rosette Server container image to use e.g. rosette/server-enterprise:1.24.1"
    exit 0
}

ROSETTE_SERVER_IMAGE=""
while [ "$#" -gt 0 ]; do
  case $1 in
    -r)
      shift
      ROSETTE_SERVER_IMAGE=$1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if [[ $ROSETTE_SERVER_IMAGE == "" ]]; then
    error "[ERROR] No Rosette Server image given"
    usage
fi

TARGET="${BASE_DIR}"
foo=$(docker pull $ROSETTE_SERVER_IMAGE 2>/dev/null)
if [[ $? -eq 0 ]]; then
  # Save rosette image with connector as a tar file
  if prompt-yes-no "Save $ROSETTE_SERVER_IMAGE to .tar.gz (y/n)?"; then
    tarGzfilename="$(echo $ROSETTE_SERVER_IMAGE | sed 's/[\/:]/-/g').tar.gz"
    msg "Saving $ROSETTE_SERVER_IMAGE to ${TARGET}/${tarGzfilename}"
    docker save $ROSETTE_SERVER_IMAGE | gzip > ${TARGET}/$tarGzfilename
    if [[ $? -ne 0 ]]; then
      error_exit "Could not save image, exiting"
    fi
  else
    msg "Not saving image to a .tar.gz"
  fi
  docker image ls $ROSETTE_SERVER_IMAGE
  if [ ! -f "${BASE_DIR}/${ENDPOINT_FILE}" ]; then
    EPS=$(grep "^.*:$" ${BASE_DIR}/scripts/package-roots.yaml | grep -v pragma | sed 's/://g' )
    for EP in $EPS; do
        echo "#$EP" >> "${BASE_DIR}/${ENDPOINT_FILE}"
    done
    info "Created ${BASE_DIR}/${ENDPOINT_FILE}"
  fi
else
  error "Could not pull $ROSETTE_SERVER_IMAGE"
fi
msg "Done"
