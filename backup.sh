#!/bin/sh

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ $# -eq 0 ] || [ $1 != 'skipapi' ]; then

    RESPONSE=$(curl -s -X POST "$SALESFORCE_OAUTH_URL")
    TIMEOUT=$((SECONDS+180))

    if jq -e . >/dev/null 2>&1 <<<"$RESPONSE"; then
        # Parsed JSON successfully and got something other than false/null
        SF_ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
        SF_INSTANCE_URL=$(echo $RESPONSE | jq -r '.instance_url')
        PAYLOAD=$(jq -n --arg accessToken "$SF_ACCESS_TOKEN" --arg instanceUrl "$SF_INSTANCE_URL" \
        --arg componentOption "unmanaged"  '{"accessToken":$accessToken,"instanceUrl":$instanceUrl,"componentOption":$componentOption}')

        # TODO: Error handling
        RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$START_JOB_URL" )
        SF_PACKAGE_ID=$(echo $RESPONSE | jq -r '.id')
        PACKAGE_DONE="false"

        echo "Start building package..."

        while [ $PACKAGE_DONE == "false" ]
        do
            if [ $SECONDS -gt $TIMEOUT  ]; then
                echo "Script is taking too long. Exiting..."
                exit 1
            fi
            sleep $INTERVAL
            echo "Still building... $SECONDS seconds passed."
            RESPONSE=$(curl -s "$STATUS_URL/$SF_PACKAGE_ID/" )
            PACKAGE_DONE=$(echo $RESPONSE | jq -r '.done')
        done

        if [ $PACKAGE_DONE == "true" ]; then
            echo 'Done building package.xml'
            RESPONSE=$(curl -s "$PACKAGE_URL/$SF_PACKAGE_ID/" )


#            Whenever you need to manipulate xml you can use this
#            echo $RESPONSE | \
#                sed -e 's/xmlns=".*"//g' | \
#                xmllint --xpath '//types/name[text()="CustomObject"]/..' - | \
#                (echo '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' && cat && echo '<version>45.0</version></Package>') | \
#                xmllint --encode UTF-8 --format - | \
#                tee > $IMPLEMENTATION_FOLDER/org/package-custom-objects.xml
#
#            ELEMENT_TO_REMOVE=$( echo $RESPONSE | \
#                                    sed -e 's/xmlns=".*"//g' | \
#                                    xmllint --xpath '//types/name[text()="CustomObject"]/..' --format - | \
#                                    sed 's/\//\\\//g' )
#            in combination with
#
#               echo $RESPONSE | \
#                xmllint --noblanks - | \
#                xmllint --encode UTF-8 --format - | \
#                tee > $IMPLEMENTATION_FOLDER/org/custom-package.xml

            echo $RESPONSE | \
                xmllint --noblanks --encode UTF-8 --format - | \
                tee > $IMPLEMENTATION_FOLDER/org/package.xml
        fi

    else
        echo "Failed to parse JSON, or got false/null"
        exit 1
    fi
fi

cp $PROPERTIES_FILE $TMP_FILE
sed -i '' -e "s/{\$SF_USERNAME}/$(echo $SF_USERNAME | sed 's/\//\\\//g')/g" \
          -e "s/{\$SF_PASSWORD}/$(echo $SF_PASSWORD | sed 's/\//\\\//g')/g" \
          -e "s/{\$SF_ENV}/$(echo $SF_ENV | sed 's/\//\\\//g')/g" \
           $PROPERTIES_FILE

cd $DIR/$IMPLEMENTATION_FOLDER

ant retrieve

if [ -e org/unpackaged/objects/Task.object ]; then
    # Task Object label are screwed up, known error (https://salesforce.stackexchange.com/questions/266416/is-anyone-getting-deployment-issues-with-task-object-new-list-views-from-46-cau)
    sed -E 's/((<label>)ENCODE.*_)([^}]+)}(.*)/\2\3\4/g' org/unpackaged/objects/Task.object > org/unpackaged/objects/Task.object.tmp
    rm org/unpackaged/objects/Task.object
    cp org/unpackaged/objects/Task.object.tmp org/unpackaged/objects/Task.object
    rm org/unpackaged/objects/Task.object.tmp
fi

cd org

zip -r $DIR/files/org_metadata_backup_$(date +%Y%m%d).zip unpackaged/

rm -rf unpackaged/
# TODO: move to arbitrary location

cd ../..

cp $TMP_FILE $PROPERTIES_FILE
rm $TMP_FILE

find $DIR/files -type f -not -path '*/\.*' -mtime +7 -exec rm -rf {} \;

exit 0