# SalesForce Metadata Backup

This is an implementation for Zien24 to backup their SalesForce org automatically.
It makes use of the Ant Migration tool provided by SalesForce and a custom implementation of a Heroku app called Package 
Builder (https://github.com/ogierzien/packagebuilder) which is a fork of [@benedwards44's](https://github.com/benedwards44/packagebuilder).
That way we keep sensitive information in house.

## Prerequisites

- A recent version of JDK
- Apache Ant 1.6 or above (install instructions also present in Readme.html)
- jq - Lightweight and flexible command-line JSON processor
- curl
- xmllint (part of libxml2)

## Setup

For Ant to work properly you need a couple of environment variables (`$JAVA_HOME`,`$ANT_HOME`) and add these to your
path. I installed Ant via Homebrew, but for Windows the paths and method to add environment variables will be different. 
I'll share my `~/.bash_profile` as example:
```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home
export ANT_HOME=/usr/local/Cellar/ant/1.10.6/libexec
export PATH="${ANT_HOME}/bin:$PATH"
```
Create a .env file from the .env.example and fill in the organisation credentials.

## Steps for Metadata backup (full backup)

For backing up and / or deploying an org's metadata you need a `package.xml`-file which determines exactly what metadata 
to retrieve and deploy. ~~We are going to split this up in 2 files, one with `CustomObjects` and one without.
This is because if there are references to CustomObjects in other metadata type you get errors.
So generally we first deploy the CustomObjects before referencing them.~~ 

To backup manually:
1. Run `./backup.sh`

To deploy manually:
1. Run `./deploy.sh <path to zipfile>`

One can schedule a daily backup by using `crontab`

## Special Notes

Because of a [bug in the Summer '19 release](https://salesforce.stackexchange.com/questions/266416/is-anyone-getting-deployment-issues-with-task-object-new-list-views-from-46-cau) of SalesForce the Task object gives trouble when deploying because when you 
back it up it adds some weird replacement variables looking like this `ENCODED:{!` as labels. We remove this 
automatically with `sed`. If anything weird pops up with the deployment of the Task Object its good to keep this in mind.

## Steps for normal data backup (incremental backup)

For backing up normal data records we use the `sdfx` command line tool. You can install it with npm as follows: 
```bash
npm -i -g sfdx-cli
```
To run SOQL queries against a SalesForce org you need to authorize through the browser once.
For subsequent calls we can authenticate using a so-called `Sfdx Auth Url` which we store in a file.
It can be stored as follows: 
```bash
sfdx force:org:display -u <user_email> --verbose | grep 'Sfdx Auth Url' | awk '{print $4}' > auth
```
After that we can authenticate using the file like this:
```bash
sfdx force:auth:sfdxurl:store -f auth
```
... which comes in handy if we want to setup a cron job instead of manually backing up.

To back up mannually:
1. Run `./backup-data.sh`