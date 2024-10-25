#!/bin/bash

WORKER_CFG="$OVERRIDE_DIR/com.basistech.ws.worker.cfg"
# Should be already in the override partition from the previous init scripts, but just in case something changes in the
# future, we'll copy it over if it's not there.
if [[ ! -f $WORKER_CFG ]]; then
  cp "$CONFIG_DIR/com.basistech.ws.worker.cfg" $WORKER_CFG
fi


sed -i "s|^\s*profile-data-root|#profile-data-root|g" $WORKER_CFG
echo -e "\nprofile-data-root=file://${CUSTOM_PROFILES_PATH}\n" >> $WORKER_CFG

FRONTEND_CFG="$OVERRIDE_DIR/com.basistech.ws.frontend.cfg"
if [[ ! -f $FRONTEND_CFG ]]; then
  cp "$CONFIG_DIR/com.basistech.ws.frontend.cfg" $FRONTEND_CFG
fi

sed -i "s|^\s*profile-data-root|#profile-data-root|g" $FRONTEND_CFG
echo -e "\nprofile-data-root=file://${CUSTOM_PROFILES_PATH}\n" >> $FRONTEND_CFG
