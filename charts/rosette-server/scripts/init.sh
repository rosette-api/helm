#!/bin/bash

OVERRIDE_DIR="/override"
CONFIG_DIR="/configs"
INIT_SCRIPTS_DIR="/init-scripts"
ROSAPI_DIR="/rosapi"

if [[ ! -d $OVERRIDE_DIR ]]; then
  echo "/override directory doesn't exist."
  exit 1
fi
if [[ ! -d $CONFIG_DIR ]]; then
  echo "/configs directory doesn't exist."
  exit 1
fi
if [[ ! -d $INIT_SCRIPTS_DIR ]]; then
  echo "/init-scripts directory doesn't exist."
  exit 1
fi
if [[ ! -d $ROSAPI_DIR ]]; then
  echo "/rosapi directory doesn't exist."
  exit 1
fi

echo "Configuring enabled endpoints"
if [[ -z $ENDPOINTS ]]; then
  echo "Endpoints are not set. Select endpoints in values.yaml to use Rosette Server"
  exit 1
fi
bash ${INIT_SCRIPTS_DIR}/override-endpoints.sh

echo "Configuring root versions"
if [[ ! -f ${INIT_SCRIPTS_DIR}/rootVersions.sh ]]; then
  echo "rootVersions.sh is missing in ${INIT_SCRIPTS_DIR}"
  exit 1
fi
bash ${INIT_SCRIPTS_DIR}/override-roots-versions.sh

if [[ -z $COREF_URL ]]; then
  echo "Indoc coref is not enabled. Not configuring"
else
  echo "Configuring indoc coref connection"
  bash ${INIT_SCRIPTS_DIR}/configure-indoc-coref-connection.sh
fi

if [[ -z $CUSTOM_PROFILES_PATH ]]; then
  echo "Custom profiles are not enabled. Not configuring"
else
  echo "Configuring custom profiles"
  bash ${INIT_SCRIPTS_DIR}/configure-custom-profiles.sh
fi


