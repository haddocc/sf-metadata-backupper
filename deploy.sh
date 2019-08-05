#!/bin/sh

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

# Task Object label are screwed up, known error (https://salesforce.stackexchange.com/questions/266416/is-anyone-getting-deployment-issues-with-task-object-new-list-views-from-46-cau)
#sed -E 's/((<label>)ENCODE.*_)([^}]+)}(.*)/\2\3\4/g' test2/objects/Task.object

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