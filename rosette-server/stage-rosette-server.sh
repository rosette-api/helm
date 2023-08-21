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

RSSTAGE="$BASE_DIR/../stage"
RSHELMDIR="$BASE_DIR/../helm/rosette-server/"
CONTAINERS="containers"
PV="persistent-volumes"

if ! prompt-yes-no "Stage Rosette Server (RS) files (y/n)?"; then
    info "Exiting"
    exit 0
fi

# Checking for license file
LICENSE=$(find "$BASE_DIR" -name 'rosette-license*.xml' -print -quit)
if [[ ! -f "$LICENSE" ]]; then
  error_exit "Rosette license file not found. It must be copied to ${BASE_DIR}"
fi

WRITERSROOTS=1
WRITERSCONTAINERS=1
WRITERSCONFIG=1
WRITERSCONF=1

RSCONTAINERDIR="$RSSTAGE/$CONTAINERS"
RSROOTSDIR="$RSSTAGE/$PV/roots"
RSCONFIGDIR="$RSHELMDIR/config"
RSCONFDIR="$RSHELMDIR/conf"

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

ENDPOINTS="${BASE_DIR}/${ENDPOINT_FILE}"
LANGUAGES="${BASE_DIR}/${LANGUAGE_FILE}"

function extract_roots() {
    local ROSETTE_SERVER_IMAGE=$1
    
    info "Installing the following endpoints:"
    # Lines that do not start with #
    EPS_TO_INSTALL=$(grep "^[^#]" ${ENDPOINTS})
    for EP in $EPS_TO_INSTALL; do
        info "\t$EP"
    done
    msg "Installing the following languages:"
    LANGS=""
    LANGS_TO_INSTALL=$(grep "^[^#]" ${LANGUAGES})
    if [[ $? -ne 0 ]]; then 
        error_exit "No languages selected, please edit ${LANGUAGES}"
    fi
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
    
    TMP=$$.rs
    TMPDIR=${BASE_DIR}/$TMP
    mkdir $TMPDIR
    msg "Pulling com.basistech.ws.worker.cfg from $ROSETTE_SERVER_IMAGE"

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
        foo="$(${BASE_DIR}/scripts/copy-files-from-image.sh $CONTAINER /data/root $TMPDIR)"
        if [ $? -eq 0 ]; then
            rm -f ${TMPDIR}/root/unpack_root_parts.sh
            mv ${TMPDIR}/root/*.tar.gz ${RSROOTSDIR}
            info "Done copying $CONTAINER"
        else
            msg "Ignore failures, some roots don't exist."
        fi
    done
    rm -rf $TMPDIR
}


info "Staging Rosette Server (RS) files to $RSSTAGE"
echo ""
info "Checking for previously staged files."
if [[ -d "$RSROOTSDIR" && $(find "$RSROOTSDIR" -name '*.tar.gz' | wc -l) -gt 0 ]]; then
    if ! prompt-yes-no "RS roots staged, overwrite (y/n)?"; then
        WRITERSROOTS=0
    fi              
fi
if [[ $WRITERSROOTS -eq 1 ]]; then 
    rm -rf "$RSROOTSDIR"
    mkdir -p "$RSROOTSDIR"        
fi
if [[ -d "$RSCONTAINERDIR" && $(find "$RSCONTAINERDIR" | wc -l) -gt 0 ]]; then
    if ! prompt-yes-no "Rosette Server containers already staged, overwrite (y/n)?"; then
        WRITERSCONTAINERS=0
    fi              
fi
if [[ $WRITERSCONTAINERS -eq 1 ]]; then 
    rm -rf "$RSCONTAINERDIR"
    mkdir -p "$RSCONTAINERDIR"        
fi

if [[ -d "$RSCONFDIR" ]]; then
    if ! prompt-yes-no "Rosette Server conf directory already staged, overwrite (y/n)?"; then
        WRITERSCONF=0
    fi              
fi
if [[ $WRITERSCONF -eq 1 ]]; then 
    rm -rf "$RSCONFDIR"
    mkdir -p "$RSCONFDIR"        
fi
if [[ -d "$RSCONFIGDIR" ]]; then
    if ! prompt-yes-no "Rosette Server config directory already staged, overwrite (y/n)?"; then
        WRITERSCONFIG=0
    fi              
fi
if [[ $WRITERSCONFIG -eq 1 ]]; then 
    rm -rf "$RSCONFIGDIR"
    mkdir -p "$RSCONFIGDIR"        
fi
echo ""

info "Staging requested Rosette Server files from Rosette Server container to $RSSTAGE"
# verify some endpoints are selected
# verify some languages are selected

# Get RS version
RS_VER=$(grep appVersion $RSHELMDIR/Chart.yaml | cut -d' ' -f2 | sed 's/"//g')
docker pull rosette/server-enterprise:$RS_VER
info "Pulling rosette/server-enterprise:$RS_VER"
X=$(docker image ls -q rosette/server-enterprise:$RS_VER)
if [[ "$X" == "" ]]; then
    error_exit "Could not pull rosette/server-enterprise:$RS_VER"
fi
RSIMAGE=rosette/server-enterprise:$RS_VER

if [[ $WRITERSROOTS -eq 1 ]]; then
    EPS_TO_INSTALL=$(grep "^[^#]" ${ENDPOINTS})
    if [[ $? -ne 0 ]]; then
        error_exit "No endpoints selected, please edit ${ENDPOINTS}."
    fi
    LANGS_TO_INSTALL=$(grep "^[^#]" ${LANGUAGES})
    if [[ $? -ne 0 ]]; then
        error_exit "No languages selected, please edit ${LANGUAGES}"
    fi
fi

if [[ $WRITERSCONTAINERS -eq 1 ]]; then
    info "Saving Rosette Server container"
    docker save $RSIMAGE | gzip > "$RSCONTAINERDIR/rosette-server-enterprise-$RS_VER.tar.gz"
    info "Updating Rosette Server image name in ${RSHELMDIR}/values.yaml"
    sed_replace 's/rosette-server-enterprise-cp/rosette-server-enterprise/g' $RSHELMDIR/values.yaml
fi

if [[ $WRITERSCONFIG -eq 1 ]]; then
    info "Extracting config and config/rosapi directory from $RSIMAGE into $RSHELMDIR"
    X=$(${BASE_DIR}/scripts/copy-files-from-image.sh $RSIMAGE /rosette/server/launcher/config "$RSHELMDIR")
    info "Disabling log file"
    sed -i 's/^#[ ]*enabled:.*/enabled: false/g' "$RSCONFIGDIR/com.basistech.ws.local.usage.tracker.cfg"
    info "Copying license file"
    cp "$LICENSE" "$RSCONFIGDIR/rosapi/rosette-license.xml"
fi

if [[ $WRITERSCONF -eq 1 ]]; then
    info "Extracting conf from ${RSIMAGE} into ${RSHELMDIR}"
    X=$(${BASE_DIR}/scripts/copy-files-from-image.sh ${RSIMAGE} /rosette/server/conf "$RSHELMDIR")
    info "Disabling local metrics file"
    # disable the other stuff
    sed -i 's/^wrapper.logfile=.*/wrapper.logfile=/g' "$RSCONFDIR/wrapper.conf"
fi

if [[ $WRITERSROOTS -eq 1 ]]; then
    info "Extracting roots"
    extract_roots $RSIMAGE
fi

