#!/bin/sh

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

sfdx force:auth:sfdxurl:store -f auth -a MainOrg

cd files

for row in $(jq '.[] | @base64' ../backup-data-cfg.json); do
     select=$(echo ${row} | xargs | base64 --decode | jq -r '.[].select')
     from=$(echo ${row} | xargs | base64 --decode | jq -r '.[].from')
     echo "Quering $from"
     sfdx force:data:soql:query -u MainOrg \
            -q "SELECT $select
                FROM $from
                WHERE LastModifiedDate > $(date -v-1d +%Y-%m-%d)T22:00:00Z
                AND LastModifiedDate < $(date +%Y-%m-%d)T22:00:00Z" \
            --resultformat csv | \
            tee > "${from}_$(date +%Y%m%d).csv"
     echo "Done backing up $from"
done

echo 'Backup done';

exit 0