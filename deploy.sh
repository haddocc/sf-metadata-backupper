#!/bin/sh

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

ZIP=$(pwd)/$IMPLEMENTATION_FOLDER/org/$1

#unzip $1 -d "$(pwd)/$IMPLEMENTATION_FOLDER/org"

cp $PROPERTIES_FILE $TMP_FILE
sed -i '' -e "s/{\$SF_USERNAME}/$(echo $SF_USERNAME | sed 's/\//\\\//g')/g" \
          -e "s/{\$SF_PASSWORD}/$(echo $SF_PASSWORD | sed 's/\//\\\//g')/g" \
          -e "s/{\$SF_ENV}/$(echo $SF_ENV | sed 's/\//\\\//g')/g" \
          -e "s/{\$SF_ZIPFILE}/$(echo $ZIP | sed 's/\//\\\//g')/g" \
           $PROPERTIES_FILE

cd $IMPLEMENTATION_FOLDER

ant deployZip

cd ..

cp $TMP_FILE $PROPERTIES_FILE
rm $TMP_FILE

exit 0