#!/bin/bash

# for deploying repo contents when pulled from code repo

THIS_DISTRO="ap20-utils/misc-utils"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

. bash.functions

if ! [ -f .env ]; then
   echo "ERROR: .env does not exist!"
   echo "Create $DIR/.env by copying/symlinking to $DIR/.env.sample and modify as required."
   exit 1
fi
. .env
if [ -z $HOSTNAME ]; then
   echo "ERROR: environemnt variable HOSTNAME is not defined!"
   exit 2
fi

# do not run if the hostname is defined in the array YGGDEP_EXCLUDED_HOSTS (see .env)
(for e in ${MY_EXCLUDED_HOSTS[@]}; do [[ "$e" == $HOSTNAME ]] && exit 0; done) && exit 2 || echo Deploying $THIS_DISTRO on $HOSTNAME

envinfo MY

# ensure dirs exist 

makedir $MY_USR_BIN                   $DEFAULT_PERMS                    775
makedir $MY_PERLLIB                   root:root                         775

# copy files

cd $DIR
for F in rfindrep.pl validateXML.pl instmodsh tellSysadmin.pl perl-installed-modules-list.sh
do
    copy ../src/$F  $MY_USR_BIN/$F $MY_DEFAULT_PERMS 775 "$1"
done
copy ../src/myEmailer.pl    $MY_PERLLIB/myEmailer.pl $MY_DEFAULT_PERMS 664 "$1"

echo "# eoj"

