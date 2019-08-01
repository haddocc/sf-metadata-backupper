#!/bin/sh

PROPERTIES_FILE=zien24_implementation/build.properties
TMP_FILE=$PROPERTIES_FILE.tmp

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

cp $PROPERTIES_FILE $TMP_FILE

sed -i '' -e "s/{\$SF_USERNAME}/$(echo $SF_USERNAME | sed 's/\//\\\//g')/g" \
       -e "s/{\$SF_PASSWORD}/$(echo $SF_PASSWORD | sed 's/\//\\\//g')/g" \
       -e "s/{\$SF_ENV}/$(echo $SF_ENV | sed 's/\//\\\//g')/g" \
       $PROPERTIES_FILE

cp $TMP_FILE $PROPERTIES_FILE

rm $TMP_FILE

exit 0