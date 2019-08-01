# SalesForce Metadata Backup

This is an implementation for Zien24 to backup their SalesForce org automatically.
It makes use of the Ant Migration tool provided by SalesForce and a custom implementation of a Heroku app called Package 
Builder (https://github.com/ogierzien/packagebuilder) which is a fork of [@benedwards44's](https://github.com/benedwards44/packagebuilder).
That way we keep sensitive information in house.

## Prerequisites

- A recent version of JDK
- Apache Ant 1.6 or above (install instructions also present in Readme.html)

## Setup

For Ant to work properly you need a couple of environment variables (`$JAVA_HOME`,`$ANT_HOME`) and add these to your
path. I installed Ant via Homebrew, but for Windows the paths and method to add environment variables will be different. 
I'll share my `~/.bash_profile` as example:
```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home
export ANT_HOME=/usr/local/Cellar/ant/1.10.6/libexec
export PATH="${ANT_HOME}/bin:$PATH"
```
Create a .env file from the .env.example and fill in the OAuth credentials.

## Steps

For backing up and / or deploying an org's metadata you need a `package.xml`-file which determines exactly what metadata 
to retrieve and deploy. We are going to split this up in 2 files, one with `CustomObjects` and one without.
This is because if there are references to CustomObjects in other metadata type you get errors.
So generally we first deploy the CustomObjects before referencing them.

To backup:
1. Run `./backup.sh`

To deploy:
1. Run `./deploy.sh`

## Special Notes

Because of a bug in the Summer '19 release of SalesForce the Task object gives trouble when deploying because when you 
back it up it adds some weird replacement variables looking like this `ENCODED:{!` as labels. We remove this 
automatically with `sed`. If anything weird pops up with the deployment of the Task Object its good to keep this in mind.
