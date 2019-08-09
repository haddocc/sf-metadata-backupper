#!/bin/sh

set -a # automatically export all variables. This requires appropriate shell quoting.
source .env
set +a

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
YESTERDAY=$(date -v -1d > /dev/null 2>&1 && date -v -1d +%Y-%m-%d || date --date="1 day ago" +%Y-%m-%d)

sfdx force:auth:sfdxurl:store -f auth -a MainOrg

cd files

for row in $(jq '.[] | @base64' ../backup-data-cfg.json); do
     select=$(echo ${row} | xargs | base64 --decode | jq -r '.[].select')
     from=$(echo ${row} | xargs | base64 --decode | jq -r '.[].from')
     echo "Quering $from"
     sfdx force:data:soql:query -u MainOrg \
            -q "SELECT $select
                FROM $from
                WHERE LastModifiedDate > ${YESTERDAY}T22:00:00Z
                AND LastModifiedDate <= $(date +%Y-%m-%d)T22:00:00Z" \
            --resultformat csv | \
            tee > "${from}_$(date +%Y%m%d).csv"
     echo "Done backing up $from"
done

echo 'Backup done';

# Only zip csv files created in the last hour
find $DIR/files -type f -not -path '*/\.*' -name "*.csv" -cmin -60 | zip -j $DIR/files/org_data_backup_$(date +%Y%m%d).zip -@
find $DIR/files -type f -not -path '*/\.*' -name "*.csv" -cmin -60 -exec rm -f {} \;

exit 0