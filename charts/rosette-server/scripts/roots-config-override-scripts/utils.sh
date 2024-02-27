#!/bin/bash
_LOGFILE="/dev/null"
function startlogging() {
  local TS=$(date +%d-%m-%y_%H-%M)
  if [[ ! -z "$1" ]]; then
    _LOGFILE="${1}.$TS.log"
    if [[ ! -f "${_LOGFILE}" ]]; then
      printf "Logging %s at %s\n" "${1}" $TS > "${_LOGFILE}"
    fi
  else
    echo "1 is empty. It is $1"
    _LOGFILE="/dev/null"
  fi
}

function stoplogging() {
  _LOGFILE="/dev/null"
}

function info() {
  echo -e "[INFO] $1" | tee -a "${_LOGFILE}" >&1
}

function warn() {
  echo -e "[WARNING] $1" | tee -a "${_LOGFILE}" >&1
}

function error() {
  echo -e "[ERROR] $1" | tee -a "${_LOGFILE}" >&1
}

function validate-target-path() {
  _TARGET_PATH=$1
  RESULT=0
  if [[ "$_TARGET_PATH" == "" ]] ; then
    RESULT=1
  fi
  ## Disallow going up the file tree, to prevent override/deletion of files outside of the roots
  if [[ "$_TARGET_PATH" =~ \.\. ]]; then
    RESULT=1
  fi
  echo $RESULT
}

function rollout-restart-rosette-server-deployment() {
  # Point to the internal API server hostname
  APISERVER=https://kubernetes.default.svc

  # Path to ServiceAccount token
  SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

  # Read this Pod's namespace
  NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

  # Read the ServiceAccount bearer token
  TOKEN=$(cat ${SERVICEACCOUNT}/token)

  # Reference the internal certificate authority (CA)
  CACERT=${SERVICEACCOUNT}/ca.crt

  CURRENT_TIME=$(date)

  # Update the Rosette Server deployment template to force rolling the pods
  curl -s -o /dev/null --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" --header "Content-type: application/strategic-merge-patch+json" -X PATCH \
  ${APISERVER}/apis/apps/v1/namespaces/${NAMESPACE}/deployments/${RS_DEPLOYMENT} \
  -d "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"rootsExtracted\":\"${CURRENT_TIME}\"}}}}}"
}