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
    SRC="$(get_input "Where are the Rosette Server configuration files? " "${BASE_DIR}")"
    if [[ ${SRC} == "" || ${SRC} == "Y" || ${SRC} == "y" ]]; then
        warn "Configuration directory can not be ${SRC}"
    else
        if [ ! -d "${SRC}/conf" ]; then
            warn "${SRC}/conf does not exist!"
        elif [ ! -d "${SRC}/config" ]; then
            warn "${SRC}/config does not exist!"
        elif [ ! -d "${SRC}/config/rosapi" ]; then
            warn "${SRC}/config/rosapi does not exist!"
        else
            break
        fi
    fi
done

# The location of the /config directory of the Rosette Server
INSTALLCONFIG=1

while true; do
    CONFIG="$(get_input "Enter base directory to install Rosette Server configuration ")"
    if [[ ${CONFIG} == "" || ${CONFIG} == "Y" || ${CONFIG} == "y" ]]; then
        warn "Config installation directory can not be ${CONFIG}"
    else
        if [ ! -d "${CONFIG}" ]; then
            if prompt-yes-no "${CONFIG}/config does not exist, create (y/n)?"; then
                mkdir -p "${CONFIG}"
                if [ $? -ne 0 ]; then
                    error_exit "Error creating ${CONFIG}"
                fi
                break
            else
                warn "Rosette Server requires configuration to be extracted in order to start!"
                if prompt-yes-no "Continue? (y/n)? y to continue without creating directory, n to enter new directory"; then
                    INSTALLCONFIG=0
                    break
                fi
            fi
        else
            if [ -d "${CONFIG}/config" ]; then
                if prompt-yes-no "${CONFIG}/config exists, use anyway (files will be overwritten) (y/n)?"; then
                    break
                fi
            else
                break
            fi
            if [ -d "${CONFIG}/conf" ]; then
                if prompt-yes-no "${CONFIG}/conf exists, use anyway (files will be overwritten) (y/n)?"; then
                    break
                fi
            else
                break
            fi

        fi
    fi
done

if [ $INSTALLCONFIG -eq 1 ]; then
    if [[ ! -d "${SRC}/conf" ]]; then 
        error_exit "Could not find ${SRC}/conf, run download-rosette-server-packages.sh? exiting"
    fi
    if [[ ! -d "${SRC}/config" ]]; then 
        error_exit "Could not find ${SRC}/config, run download-rosette-server-packages.sh? exiting"
    fi
    cp -r ${SRC}/conf ${CONFIG}/conf
    if [[ $? -eq 1 ]]; then
        error_exit "Failed copying ${SRC}/conf to ${CONFIG}/conf"
    else
        info "Copied ${SRC}/conf to ${CONFIG}/conf"
    fi
    cp -r ${SRC}/config ${CONFIG}/config
    if [[ $? -eq 1 ]]; then
        error_exit "Failed copying ${SRC}/config to ${CONFIG}/config"
    else
        info "Copied ${SRC}/config to ${CONFIG}/config"
    fi
fi
