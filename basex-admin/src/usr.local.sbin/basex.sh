#!/bin/sh

# april 2013 sms Script to start/stop basex server as fas with databases passed as -D options to java

# We must be passed stop | start

if [ "$1" = "start" ]; then
   echo "-- $0 $1"
elif [ "$1" = "stop" ]; then
   echo "-- $0 $1"
elif [ "$1" = "status" ]; then
   echo "-- $0 $1"
else
   echo "usage: $0 stop|start|status"
   exit 1
fi

############################# 1. ensure /tmp/basex exists for www-data

BASEXTMP="/tmp/basex"
BASEX_USER='fas'
BASEX_HOME="/srv/basex/basex"
BASEX_DATABASES="/data/bx/db"
BASEX_MYSETTINGSDIR="/srv/basex/.mysettings"

if [ -d $BASEXTMP ]; then
  #echo "$0: $BASEXTMP exists"
  chmod 777 $BASEXTMP
else
  #echo "$0: $BASEXTMP does not exist!"
  mkdir $BASEXTMP
  chown $BASEX_USER:$BASEX_USER $BASEXTMP
  chmod 777 $BASEXTMP
  echo "$0: Created:"
  ls -la $BASEXTMP
fi

############################ 2. determine custom options such as what databases we are using

  # pass in "set DBPATH /data/bx/db" if that dir exists
  me=`basename $0`
  instance=`echo $me | sed 's/\.sh//'`

  # set defaults for options

  # jvm assumes a small instance 4gb ram total, take up to half
  # -Xmx hardcoded in bin/mybasexhttp as VM=-Xmx3072m BX_JVMSIZE="-d64 -Xms1024m -Xmx2048m"
  # the mybasexhttp script picks up the -X and passes what follows to java
  BX_JVMSIZE="-X -Xms1024m -X -Xmx2048m"

  # take basex default {home}/data for dbpath
  # or pass in "set DBPATH /data/bx/db" if that dir is found to exist
  # (nb: this enables basex software to be installed on /srv on Nectar but if 2nd disk
  #      /dev/vdb contains the dir $BASEX_DATABASES (see above) then unless otherwise
  #      specified in the
  BX_DBPATH=""
  if [ -d $BASEX_DATABASES ]; then
     BX_DBPATH="$BASEX_DATABASES"
     echo "Our default path for databases: BASEX_DATABASES[$BASEX_DATABASES]"
  fi

  # source a custom settings file if present
  CUSTOM_SETTINGS_FILE="$BASEX_MYSETTINGSDIR/$instance"
  if [ -f $CUSTOM_SETTINGS_FILE ]; then
     echo "sourcing $CUSTOM_SETTINGS_FILE"
     . $CUSTOM_SETTINGS_FILE
  fi

  # set the dbpath via passing -Dproperty=value to java
  # and check if its running with those databases

  if [ "$BX_DBPATH" = "" ]; then
      OPTIONS="$BX_JVMSIZE"
      MSG="logs at $BASEX_HOME/data/.logs"
      LOOKFOR="org.basex"
  else
      OPTIONS="$BX_JVMSIZE -D org.basex.DBPATH=$BX_DBPATH"
      MSG="logs at $BX_DBPATH/.logs"
      LOOKFOR="org.basex.DBPATH=$BX_DBPATH"
  fi
 
############################ 3. check basex is running; start it if needed
basexRunning=`ps afx|grep "$LOOKFOR"|grep -v grep|head -1`

echo "$0: .dbg: BXRUN[$BXRUN] basexRunning($LOOKFOR)=[$basexRunning]"

if [ -n "$basexRunning" ]; then
  if [ "$1" = "stop" ]; then
     echo "su $BASEX_USER --command bin/mybasexhttpstop $OPTIONS -"
     cd $BASEX_HOME
     su $BASEX_USER --command "bin/mybasexhttpstop $OPTIONS" -
  elif [ "$1" = "status" ]; then
     echo "Basex is running OPTIONS[$OPTIONS]"
  else
     echo "$0: IGNORE start request -- basex is already running options[$OPTIONS]."
  fi
else
  if [ "$1" = "start" ]; then
     echo "$0: starting basex as $BASEX_USER using OPTIONS[$OPTIONS] BX_DBPATH[$BX_DBPATH] jvm[$BX_JVMSIZE]"
     echo "cd to BASEX_HOME[$BASEX_HOME]"
     echo "su $BASEX_USER --command bin/mybasexhttp $OPTIONS # Note: $MSG"
     cd $BASEX_HOME
     su $BASEX_USER --command "nohup bin/mybasexhttp $OPTIONS &" -
  elif [ "$1" = "status" ]; then
     echo "Basex is NOT running"
  else
     echo "$0: IGNORE stop request -- basex is NOT running."
  fi
fi

exit 0
