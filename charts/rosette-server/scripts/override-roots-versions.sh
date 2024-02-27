#!/bin/bash

source /init-scripts/rootVersions.sh

function update-root-version() {
  local FILE=$1
  local KEY=$2
  local ROOT=$3
  local VERSION=$4

  # Comment out the key
  sed -i "s|^\s*${KEY}|#${KEY}|g" ${FILE}
  # Add version from values.yaml
  echo -e "\n${KEY}=\${rosapi.roots}/${ROOT}/${VERSION}\n" >> ${FILE}
}

function update-flinx-version() {
  local FILE=$1
  local VERSION=$2

  # Comment out the key
  sed -i "s|^\s*flinx-root|#flinx-root|g" ${FILE}
  # Add version from values.yaml
  echo -e "\nflinx-root=\${rosapi.roots}/rex/${VERSION}/flinx\n" >> ${FILE}
}

WORKER_CFG="/override/com.basistech.ws.worker.cfg"
if [[ ! -f $WORKER_CFG ]]; then
  WORKER_CFG="/configs/com.basistech.ws.worker.cfg"
fi
update-root-version $WORKER_CFG "ascent-root" "ascent" $ASCENT
update-root-version $WORKER_CFG "dp-root" "nlp4j" $NLP4J
update-root-version $WORKER_CFG "rbl-root" "rbl" $RBL
update-root-version $WORKER_CFG "rct-root" "rct" $RCT
update-root-version $WORKER_CFG "relax-root" "relax" $RELAX
update-root-version $WORKER_CFG "rex-root" "rex" $REX
update-flinx-version $WORKER_CFG $REX
update-root-version $WORKER_CFG "rli-root" "rli" $RLI
update-root-version $WORKER_CFG "rni-rnt-root" "rni-rnt" $RNIRNT
update-root-version $WORKER_CFG "tcat-root" "tcat" $TCAT
update-root-version $WORKER_CFG "topics-root" "topics" $TOPICS
update-root-version $WORKER_CFG "tvec-root" "tvec" $TVEC


