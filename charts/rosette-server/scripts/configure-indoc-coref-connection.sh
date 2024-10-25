#!/bin/bash

cp $ROSAPI_DIR/rex-factory-config.yaml $OVERRIDE_DIR/rex-factory-config.yaml
sed -i "s|^\s*indocCorefServerUrl|#indocCorefServerUrl|g" $OVERRIDE_DIR/rex-factory-config.yaml
echo -e "\nindocCorefServerUrl: http://$COREF_URL\n" >> $OVERRIDE_DIR/rex-factory-config.yaml