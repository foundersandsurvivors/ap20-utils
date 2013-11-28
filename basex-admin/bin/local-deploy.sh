#!/bin/bash

# for deploying repo contents when pulled from code repo
THIS_DISTRO="ap20-utils/basex-admin"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

# this will source /etc./environment and defines functions which we use here
. bash.functions

# source the variables needed for installation/deployment
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
(for e in ${BASEX_EXCLUDED_HOSTS[@]}; do [[ "$e" == $HOSTNAME ]] && exit 0; done) && exit 2 || echo Deploying $THIS_DISTRO on $HOSTNAME

# check that the runtime environment variables have been set
if [[ -f ../src/etc/environment ]]; then
   env_vars=`perl -ne 'print if (s/^export (\S+)=.+\n/\1 /);' ../src/etc/environment`
   if ! [[ "$env_vars" == "" ]]; then
       checkenv "$env_vars"
   fi
fi

if [[ "$1" == "check" ]]; then
   envinfo BASEX
   echo "-- [check] was specified. Not proceeding."
   exit 0
fi

# ensure dirs exist

makedir $BASEX_ADMIN                  $BASEX_DEFAULT_PERMS              775
makedir $BASEX_ADMIN/bin              $BASEX_DEFAULT_PERMS              775
makedir $BASEX_ADMIN/logs             $BASEX_DEFAULT_PERMS              775
makedir $BASEX_ADMIN/scripts          $BASEX_DEFAULT_PERMS              775
makedir $BASEX_ADMIN/webwork          $BASEX_DEFAULT_PERMS              775
makedir $BASEX_ADMIN/webwork/schemas  $BASEX_DEFAULT_PERMS              775
makedir $BASEX_ADMIN/.mysettings      $BASEX_DEFAULT_PERMS              775

# copy files

cd $DIR
copy ../src/etc.init.d/basex        /etc/init.d/basex        root:root 755 "$1"
copy ../src/usr.local.sbin/basex.sh /usr/local/sbin/basex.sh root:root 744 "$1"
for F in ../src/basex-admin/bin/*
do
   B=`basename $F`
   if ! [ "$B" == "README.md" ]; then copy $F $BASEX_ADMIN/bin/$B $BASEX_DEFAULT_PERMS 775 "$1"; fi
done
copy ../src/basex-admin/.mysettings/basex.sample $BASEX_ADMIN/.mysettings/basex.sample $BASEX_DEFAULT_PERMS 664 "$1"
for F in ../src/basex-admin/webwork/schemas/*
do
   B=`basename $F`
   copy $F $BASEX_ADMIN/webwork/schemas/$B $BASEX_DEFAULT_PERMS 664 "$1"
done

echo "# eoj"

