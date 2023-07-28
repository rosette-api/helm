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

while true; do
    SRC="$(get_input "Where are the compressed Rosette Server roots? " "${BASE_DIR}/../stage/persistent-volumes/roots")"
    if [[ ${SRC} == "" || ${SRC} == "Y" || ${SRC} == "y" ]]; then
        warn "Roots directory can not be ${SRC}"
    else
        if [ ! -d "${SRC}" ]; then
            warn "${SRC} does not exist!"
        else
            CNT=$(ls -1 ${SRC}/*.tar.gz 2>/dev/null | wc -l)
            if [[ $CNT -eq 0 ]]; then
                warn "No .tar.gz found in ${SRC}"
            else
                break
            fi
        fi
    fi
done

EXTRACTROOTS=1
while true; do
    ROOTS="$(get_input "Where should Rosette Server roots be extracted? ")"
    if [[ ${ROOTS} == "" || ${ROOTS} == "Y" || ${ROOTS} == "y" ]]; then
        warn "Roots directory can not be ${ROOTS}"
    else
        if [ ! -d "${ROOTS}" ]; then
            if prompt-yes-no "${ROOTS} does not exist, create (y/n)?"; then
                mkdir -p ${ROOTS}
                if [ $? -ne 0 ]; then
                    error_exit "Error creating ${ROOTS}"
                fi
                break
            else
                warn "Rosette Server requires roots in order to start!"
                if prompt-yes-no "Continue? (y/n)? y to continue without creating directory, n to enter new directory"; then
                    EXTRACTROOTS=0
                    break
                fi
            fi
        else
            if prompt-yes-no "${ROOTS} already exists, use anyway (y/n)?"; then
                break
            fi
        fi
    fi
done

if [[ $EXTRACTROOTS -eq 1 ]]; then
    if prompt-yes-no "Install roots from ${SRC} to ${ROOTS} (y/n)?"; then
        if [[ -d ${SRC} ]]; then
            for f in $(ls ${SRC}/*.tar.gz); do
                tar xvfz $f -C ${ROOTS}
            done
        else
            warn "No roots found in package (${SRC})"
        fi
    else
        info "Roots must be deployed in order to start Rosette Server!"
    fi
fi
