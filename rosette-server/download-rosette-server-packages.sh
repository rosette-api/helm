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

ENDPOINTS="${BASE_DIR}/${ENDPOINT_FILE}"
LANGUAGES="${BASE_DIR}/${LANGUAGE_FILE}"
# Install roots here
TARGET="${BASE_DIR}"

create_endpoint_file "${BASE_DIR}"

function usage() {
    msg "usage $0 -r rosette image"
    msg "\t-r the Rosette Server container image to use e.g. rosette/server-enterprise:1.20.4"
    msg "\t\tEdit the file ${ENDPOINTS} and uncomment the endpoints you would like to have installed"
    msg "\t\tEdit the file ${LANGUAGES} and uncomment the languages you would like to install"
    msg "\t\tAll the needed data models (roots) will be downloaded from the container registry and saved"
    msg "\t\tThe Rosette Server config and config/rosapi directories will be extracted"
    msg "\t\tThe Rosette Server conf directory will be extracted"
    exit 0
}

# Make endpoints-to-install.txt
if [ -f ${ENDPOINTS} ]; then
    CNT=$(grep -c -e "^[a-zA-Z]" ${ENDPOINTS})
    if [[ $CNT -eq 0 ]]; then
        error "Please select some endpoints to install by uncommenting the desired endpoints in ${ENDPOINTS}."
        usage
    fi
fi
CNT=$(grep -c -e "^[a-zA-Z]" ${LANGUAGES})
if [[ $CNT -eq 0 ]]; then
    error "Please select some languages to install by uncommenting the desired langauges in ${LANGUAGES}."
    usage
fi

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

# Makes the docker image root name given the tar.gz filename from package-roots.yaml
# The version to use is the worker cfg file from the Rosette Server being used
function make_dockername() {
    TAR=$1
    VERSIONS=$2
    
    # Example Transformations
    # - rex-root-hun-7.47.0.c62.2.tar.gz -> rosette/root-rex-eng:7.49.1.c63.0
    # - rbl-root-7.37.0.c62.2.tar.gz -> rosette/root-rbl:7.39.0.c63.0
    # - tvec-root-eng-4.6.0.c62.2.tar.gz -> rosette/root-tvec-eng:4.6.2.c63.0
    
    # remove leading " - " and trailing ".tar.gz"
    # ex. - rex-root-hun-7.47.0.c62.2.tar.gz -> rex-root-hun-7.47.0.c62.2
    TAR=$(echo $TAR | sed 's/^ *- *//g')
    TAR=${TAR%".tar.gz"}

    # Determine the version to use by looking in the worker config file
    # ex. rbl-root=${rosapi.roots}/rbl/7.39.0.c63.0

    # Strip off everything from the tar.gz filename starting with -root
    # ex. rex-root-hun-7.47.0.c62.2 -> rex
    TMP=$(echo $TAR | sed 's/-root.*$/-root/g')
    if [[ $TMP == "nlp4j-root" ]] ; then
        TMP="dp-root"
    fi
    # Look for the root name in the worker config file
    VERSION=$(grep -i -E "^$TMP" $VERSIONS)
    # Version will be everything after the last slash
    VERSION="${VERSION##*/}"

    # move '-root' to front and replace hyphen version with colon version
    # ex. rex-root-hun-7.47.0.c62.2 -> rex-hun:7.47.0.c62.2
    TAR=$(echo $TAR | sed 's/-root//g')
    # change -[0-9] to :[0-9]
    TAR=$(echo $TAR | sed -E 's/-([0-9])/:\1/')

    # replace the version with the one from the server config and prepend 'rosette/root-'
    # ex. rex-hun:7.47.0.c62.2 -> rosette/root-rex-hun:<updated version>
    TAR=$(echo $TAR | sed "s/:.*$/:$VERSION/g")
    TAR="rosette/root-"${TAR}

    # stupid special case
    TAR=$(echo $TAR | sed 's/root-rex:/root-rex-root:/g')
    echo $TAR
}


while true; do
    ROOTSDIR="$(get_input "Enter base download directory for roots" "${TARGET}")"
    if [[ ${ROOTSDIR} == "" || ${ROOTSDIR} == "Y" || ${ROOTSDIR} == "y" ]]; then
        warn "Root installation directory can not be ${ROOTSDIR}"
    else
        if [ ! -d "${ROOTSDIR}" ]; then
            if prompt-yes-no "${ROOTSDIR} does not exist, create (y/n)?"; then
                mkdir -p "${ROOTSDIR}"
                break
            else
                warn "Roots must exist in order to run Rosette Server"
                if prompt-yes-no "Quit installation (y/n)?"; then
                    exit 1
                fi
            fi
        else
            if prompt-yes-no "${ROOTSDIR} exists, use anyway (files will be overwritten) (y/n)?"; then
                break
            fi
        fi
    fi
done
while true; do
    CONFDIR="$(get_input "Enter base download directory for conf" "${ROOTSDIR}")"
    if [[ ${CONFDIR} == "" || ${CONFDIR} == "Y" || ${CONFDIR} == "y" ]]; then
        warn "Conf installation directory can not be ${CONFDIR}"
    else
        if [ ! -d "${CONFDIR}/conf" ]; then
            if prompt-yes-no "${CONFDIR}/conf does not exist, create (y/n)?"; then
                mkdir -p "${CONFDIR}"
                break
            else
                warn "Conf dir must exist in order to run Rosette Server"
                if prompt-yes-no "Quit installation (y/n)?"; then
                    exit 1
                fi
            fi
        else
            if prompt-yes-no "${CONFDIR}/conf exists, use anyway (files will be overwritten) (y/n)?"; then
                break
            fi
        fi
    fi
done
while true; do
    CONFIGDIR="$(get_input "Enter base download directory for config" "${CONFDIR}")"
    if [[ ${CONFIGDIR} == "" || ${CONFIGDIR} == "Y" || ${CONFIGDIR} == "y" ]]; then
        warn "Config installation directory can not be ${CONFIGDIR}"
    else
        if [ ! -d "${CONFIGDIR}/config" ]; then
            if prompt-yes-no "${CONCONFIGDIRFDIR}/config does not exist, create (y/n)?"; then
                mkdir -p "${CONFIGDIR}"
                break
            else
                warn "Config dir must exist in order to run Rosette Server"
                if prompt-yes-no "Quit installation (y/n)?"; then
                    exit 1
                fi
            fi
        else
            if prompt-yes-no "${CONFIGDIR}/config exists, use anyway (files will be overwritten) (y/n)?"; then
                break
            fi
        fi
    fi
done


info "Installing the following endpoints:"
# Lines that do not start with #
EPS_TO_INSTALL=$(grep "^[^#]" ${ENDPOINTS})
if [[ $? -ne 0 ]]; then 
    error_exit "No endpoints selected, please edit ${ENDPOINTS}"
fi

for EP in $EPS_TO_INSTALL; do
    info "\t$EP"
done

msg "Installing the following languages:"

LANGS=""
LANGS_TO_INSTALL=$(grep "^[^#]" ${LANGUAGES})
for lang in $LANGS_TO_INSTALL; do
    code=$(read_key "${BASE_DIR}/scripts/languages.properties" "$lang" "XXX")
    info "\t$lang"
    if [[ $code != "XXX" ]]; then
        if [[ $LANGS == "" ]]; then
            LANGS=$code
        else
            LANGS=$LANGS,$code
        fi
    fi
done

msg "About to install data model (roots) and configuration directories"

if ! prompt-yes-no "Continue with installation (y/n)?"; then
    info "Installation stopped"
    exit 0
fi

msg "Pulling com.basistech.ws.worker.cfg from $ROSETTE_SERVER_IMAGE"
if [[ $ROSETTE_SERVER_IMAGE == "" ]]; then
  error_exit "ROSETTE_SERVER_IMAGE not defined,  exiting"
fi

foo=$(docker pull $ROSETTE_SERVER_IMAGE 2>/dev/null)
if [[ $? -ne 0 ]]; then
  # lets load the image                                                           
  msg "Image not found in docker, loading image from disk"
  foo=$(docker load < $(find ${BASE_DIR}/rosette-server-enterprise-*.tar.gz))
  if [[ $? -ne 0 ]]; then
    error_exit "Could not find container to load, exiting"
  fi
fi

info "Extracting config and config/rosapi directory from ${ROSETTE_SERVER_IMAGE}"
${BASE_DIR}/scripts/copy-files-from-image.sh ${ROSETTE_SERVER_IMAGE} /rosette/server/launcher/config "${CONFIGDIR}/"
if [[ $? -eq 1 ]]; then
    error "Failed copying /rosette/server/launcher/config exiting from $ROSETTE_SERVER_IMAGE"
    exit 1
fi

info "Extracting conf from ${ROSETTE_SERVER_IMAGE} into ${CONFDIR}"
${BASE_DIR}/scripts/copy-files-from-image.sh ${ROSETTE_SERVER_IMAGE} /rosette/server/conf "${CONFDIR}/"
if [[ $? -eq 1 ]]; then
    error "Failed copying /rosette/server/conf/wrapper.conf exiting from $ROSETTE_SERVER_IMAGE"
    exit 1
fi

info "Pulling roots"

TMP=$$
TMPDIR=${BASE_DIR}/$TMP
mkdir ${TMPDIR}
ROOTS_TO_PULL="${TMPDIR}/roots_to_pull.txt"
WORKER_CFG="${TMPDIR}/com.basistech.ws.worker.cfg"
if [ ! -f "${WORKER_CFG}" ]; then
    info "$WORKER_CFG does not exist, pulling..."
    imageid=$(docker image ls -q $ROSETTE_SERVER_IMAGE)
    if [[ $imageid != "" ]]; then
        ${BASE_DIR}/scripts/copy-files-from-image.sh ${ROSETTE_SERVER_IMAGE} /rosette/server/launcher/config/com.basistech.ws.worker.cfg "${TMPDIR}/"
        if [[ $? -eq 1 ]]; then
            error "Failed copying /rosette/server/launcher/config/com.basistech.ws.worker.cfg exiting"
            rm -rf $TMPDIR
            exit 1
        fi
    else
        error "$ROSETTE_SERVER_IMAGE does not exist, exiting."
        rm -rf $TMPDIR
        exit 1
    fi
fi

# Read package roots file. This file has the following pattern:
#    endpoint:
#      - root-file-name-version.tar.gz
# ex.
# morphology:
#  - rbl-root-7.37.0.c62.2.tar.gz
#  - rli-root-7.23.0.c62.2.tar.gz
for EP in $EPS_TO_INSTALL; do
    PROCESS_ROOTS=0
    while read -r line; do 
        # If we read a line and are currently processing roots
        # make sure we didn't just read a new endpoint name
        # endpoint names start in the first column and end with a colon.
        # e.g. language:
        if [[ $PROCESS_ROOTS -eq 1 ]]; then
            X=$(echo $line | grep "^.*:$")
            if [[ $? -eq 0 ]]; then 
                PROCESS_ROOTS=0
            else
                # see if this is a language root and if we are interested in that particular language
                # Language roots look like *-root-LANG-CODE-version ex. rex-root-hun-7.47.0.c62.2.tar.gz
                X=$(echo $line | grep -e "-root-[a-z][a-z][a-z]-[0-9]")
                if [[ $? -eq 0 ]]; then 
                    # Check this language root against our list of languages to install
                    for lang in $(echo $LANGS | sed "s/,/ /g"); do
                        X=$(echo $line | grep $lang)
                        if [[ $? -eq 0 ]]; then
                            # We want this language root, figure out the docker image name for it and write it to a tmp file           
                            NAME=$(make_dockername "$line" ${WORKER_CFG})
                            echo $NAME >> $ROOTS_TO_PULL
                        fi
                    done
                else
                    # otherwise, it is a root we need so write it to the tmp file
                    NAME=$(make_dockername "$line" ${WORKER_CFG})
                    echo $NAME >> $ROOTS_TO_PULL
                fi
            fi
        fi
        # If the line read equals an endpoint we want then start processing roots
        #
        if [[ $line == "${EP}:" ]]; then
            PROCESS_ROOTS=1
        fi
    done < ${BASE_DIR}/scripts/package-roots.yaml
done

# For the roots we need to install just take the unique docker images and extract the root from it
for CONTAINER in $(cat $ROOTS_TO_PULL  | sort -u); do
    info "Downloading $CONTAINER"
    foo="$(${BASE_DIR}/scripts/copy-files-from-image.sh $CONTAINER /data/root $ROOTSDIR)"
    if [ $? -eq 0 ]; then
        rm -f ${ROOTSDIR}/root/unpack_root_parts.sh
        info "Done copying $CONTAINER"
    else
        msg "Ignore failures, some roots don't exist."
        warn "Error pulling $CONTAINER"
    fi
done
rm -rf $TMPDIR
msg "Done"
