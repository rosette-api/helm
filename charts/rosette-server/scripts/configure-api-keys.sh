#!/bin/bash

# Update wrapper.conf #####
WRAPPER_CONF="$OVERRIDE_DIR/wrapper.conf"

if [ ! -f $WRAPPER_CONF ]; then
  cp $CONF_DIR/wrapper.conf $OVERRIDE_DIR/wrapper.conf
fi

#Get a free number for the java additional properties
#Skips the commented out numbers as well on the off chance a later script uncomments them
counter=402
while grep -q "wrapper.java.additional.${counter}=-Drosapi.feature.ENABLE_API_KEYS" $WRAPPER_CONF; do
  counter=$((counter+1))
done

#If it is already enabled, comment it out, and then add the new value
sed -i -E "s/^\s*wrapper.java.additional.[0-9]+=-Drosapi.feature.ENABLE_API_KEYS.*/#wrapper.java.additional.$counter=-Drosapi.feature.ENABLE_API_KEYS=/g" $WRAPPER_CONF
echo -e "\nwrapper.java.additional.$counter=-Drosapi.feature.ENABLE_API_KEYS=true" >> $WRAPPER_CONF

# Update the config file #####
CONFIG_FILE=$OVERRIDE_DIR/com.basistech.ws.apikeys.cfg
if [ ! -f $CONFIG_FILE ]; then
  cp $CONFIG_DIR/com.basistech.ws.apikeys.cfg $OVERRIDE_DIR/com.basistech.ws.apikeys.cfg
fi

function overwrite() {
  local key=$1
  local value=$2
  local file=$3
  sed -i -E "s/^\s*$key.*/#$key=/g" $file
  echo -e "\n$key=$value" >> $file
}

overwrite dbConnectionMode server $CONFIG_FILE
overwrite dbURI "$APIKEYS_URL" $CONFIG_FILE
overwrite dbName "$DB_NAME" $CONFIG_FILE

overwrite dbUser $DB_USER $CONFIG_FILE
overwrite dbPassword $DB_PASSWORD $CONFIG_FILE
overwrite dbSSLMode false $CONFIG_FILE

# Add the the info endpoint to the unsecured list if it is customized (not commented out)
sed -i -E "/^\s*unsecuredEndpoints=/ s/$/,v1\\/info/" $CONFIG_FILE

# Wait for the DB to become available #####
function isDatabaseReady() {
  java -cp /rosette/server/cli-lib/h2*.jar org.h2.tools.Shell -url "jdbc:h2:tcp:$APIKEYS_URL/$DB_NAME" -user $DB_USER -password $DB_PASSWORD -sql "SELECT 1" > /dev/null 2>&1
  return $?
}

timeout_counter=0

echo "Waiting for database to be available"
while ! isDatabaseReady; do

  if [ $timeout_counter -gt 9 ]; then
    echo "Timed out waiting for database to be available"
    # Run it one more time to the exception is logged for the user.
    java -cp /rosette/server/cli-lib/h2*.jar org.h2.tools.Shell -url "jdbc:h2:tcp:$APIKEYS_URL/$DB_NAME" -user $DB_USER -password $DB_PASSWORD -sql "SELECT 1"
    exit 1
  fi

  echo "Waiting for database to be available. Sleeping 5s"
  sleep 5
  timeout_counter=$((timeout_counter+1))
done
echo "Database is available"
