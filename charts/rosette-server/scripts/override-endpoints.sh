#!/bin/bash

cp $CONFIG_DIR/com.basistech.ws.worker.cfg $OVERRIDE_DIR
sed -i "s|^\s*overrideEndpointsPathname|#overrideEndpointsPathname|g" $OVERRIDE_DIR/com.basistech.ws.worker.cfg
echo -e "\noverrideEndpointsPathname=/rosette/server/override/config/enabled-endpoints.yaml\n" >> $OVERRIDE_DIR/com.basistech.ws.worker.cfg
echo "endpoints:" > $OVERRIDE_DIR/enabled-endpoints.yaml
for endpoint in $ENDPOINTS; do
  echo "- /${endpoint}" >> $OVERRIDE_DIR/enabled-endpoints.yaml;
done