#!/bin/sh

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

RESPONSE=$(curl -s -X POST "$SALESFORCE_OAUTH_URL")
TIMEOUT=$((SECONDS+180))

if jq -e . >/dev/null 2>&1 <<<"$RESPONSE"; then
    # Parsed JSON successfully and got something other than false/null
    SF_ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
    SF_INSTANCE_URL=$(echo $RESPONSE | jq -r '.instance_url')
    PAYLOAD=$(jq -n --arg accessToken "$SF_ACCESS_TOKEN" --arg instanceUrl "$SF_INSTANCE_URL" \
    --arg componentOption "all"  '{"accessToken":$accessToken,"instanceUrl":$instanceUrl,"componentOption":$componentOption}')

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
        echo $RESPONSE > $IMPLEMENTATION_FOLDER/org/package.xml
    fi

    cp $PROPERTIES_FILE $TMP_FILE
    sed -i '' -e "s/{\$SF_USERNAME}/$(echo $SF_USERNAME | sed 's/\//\\\//g')/g" \
              -e "s/{\$SF_PASSWORD}/$(echo $SF_PASSWORD | sed 's/\//\\\//g')/g" \
              -e "s/{\$SF_ENV}/$(echo $SF_ENV | sed 's/\//\\\//g')/g" \
               $PROPERTIES_FILE
    cp $TMP_FILE $PROPERTIES_FILE
    rm $TMP_FILE

    exit 0
else
    echo "Failed to parse JSON, or got false/null"
    exit 1
fi