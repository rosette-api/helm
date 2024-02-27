#!/bin/bash

cp /configs/com.basistech.ws.worker.cfg /override
sed -i "s|^\s*overrideEndpointsPathname|#overrideEndpointsPathname|g" /override/com.basistech.ws.worker.cfg
echo -e "\noverrideEndpointsPathname=/rosette/server/override/config/enabled-endpoints.yaml\n" >> /override/com.basistech.ws.worker.cfg
echo "endpoints:" > /override/enabled-endpoints.yaml
for endpoint in $ENDPOINTS; do
  echo "- /${endpoint}" >> /override/enabled-endpoints.yaml;
done