#!/bin/bash

cp /rosapi/rex-factory-config.yaml /override/rex-factory-config.yaml
sed -i "s|^\s*indocCorefServerUrl|#indocCorefServerUrl|g" /override/rex-factory-config.yaml
echo -e "\nindocCorefServerUrl: http://$COREF_URL\n" >> /override/rex-factory-config.yaml