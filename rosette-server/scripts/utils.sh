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
LANGUAGE_FILE=languages-to-install.txt
ENDPOINT_FILE=endpoints-to-install.txt

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
green=$(tput setaf 2)
bold=$(tput bold)
standout=$(tput smso)
reset=$(tput sgr0)

function msg {
    echo -e "${green}$1${reset}" >&2
}
function error {
    echo -e "${bold}${red}Error: $1${reset}" >&2
}
function warn {
    echo -e "${red}Warning: $1${reset}" >&2
}
function info {
    echo -e "${yellow}Info: $1${reset}" >&2
}
function error_exit {
    echo -e "${bold}${red}Error: $1${reset}" >&2
    exit "${2:-1}"
}
function get_input {
    local _DEFAULT_DISPLAY
    local _RESPONSE
    [[ "$2" == "" ]] && _DEFAULT_DISPLAY="" || _DEFAULT_DISPLAY="(default: "$'\x1B[1m'"$2"$'\x1B[0m'")"
    read -r -p "$1 $_DEFAULT_DISPLAY -> " _RESPONSE
    eval _VALUE=$(echo ${_RESPONSE:-$2})
    echo $_VALUE
}
function prompt-yes-no {
    while true; do
        read -p "$1 " yn
        case $yn in
            [Yy]* ) return 0; break;;
            [Nn]* ) return 1; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}
# Parameter 1 is the properties file to read
# Parameter 2 is the key
# Parameter 3 is the value to return if the key is not found
#
function read_key {

    if [[ $1 == "" ]]; then
        error "[ERROR] No file given"
        exit 1
    fi
    local _KEY=$2
    if [[ $_KEY == "" ]]; then
        error "[ERROR] No key given"
        exit 1
    fi

    local _DEFAULT_RESPONSE=$3

    while IFS= read -r line
    do
        if [[ "$line" =~ ^$_KEY= ]]; then
          retval=${line#*=}
          if [[ ${retval} == "" ]]; then
            retval="$_DEFAULT_RESPONSE"
          fi
          eval _VALUE="$(printf "%q" "$(echo "${retval}")")"
          echo $_VALUE
          return
        fi
    done < "$1"
    eval _VALUE="$(printf "%q" "$(echo "${_DEFAULT_RESPONSE}")")"
    echo $_VALUE
}

function comment_out_languages {
    local BASE=$1
    # comment out all selected languages
    if [[ "$OSTYPE" == "linux-gnu" ]] ; then
        sed -i '/^[a-zA-Z].*/{s/^/#/}' "${BASE}/${LANGUAGE_FILE}"
    else
        sed -i '' '/^[a-zA-Z].*/{s/^/#/}' "${BASE}/${LANGUAGE_FILE}"
    fi
}

function create_endpoint_file {
    local BASE=$1
    if [ ! -f "${BASE}/${ENDPOINT_FILE}" ]; then
        EPS=$(grep "^.*:$" ${BASE}/scripts/package-roots.yaml | grep -v pragma | sed 's/://g' )
        for EP in $EPS; do
            echo "#$EP" >> "${BASE}/${ENDPOINT_FILE}"
        done
        if [[ "$OSTYPE" == "linux-gnu" ]] ; then
            sed -i 's/^#language/language/g' "${BASE}/${ENDPOINT_FILE}"
        else
            sed -i '' 's/^#language/language/g' "${BASE}/${ENDPOINT_FILE}"
        fi
    fi
}
