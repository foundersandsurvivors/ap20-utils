#!/bin/bash

DB="$1"
XMLLOC="/data/bx/xml"
RSYNC="$2"
INPUTDIR="$XMLLOC/$DB"

if [ "$DB" == "" ]; then
   echo "usage: $0 database [rsync] (If rsync specified, xml will be synced from devfas:/srv/basex/basex)"
   exit 1
fi

echo "#-- $0 create a db on local basex /data/bx/xml"
echo ""

if [ "$RSYNC" == "" ]; then
    if [ -d $INPUTDIR ]; then
        echo "-- No rsync, $INPUTDIR exists"
    else
        echo "-- No rsync, $INPUTDIR does NOT exist. Run with \"rsync\" option?"
        exit 2
    fi
else
    echo "-- running rsync from devfas to $XMLLOC"
    sudo rsync -vax root@devfas:/srv/basex/basex/$DB $XMLLOC
    sudo touch $XMLLOC/$DB
fi

# Create .bxs command files in /srv/basex/scripts/replacedb-vjs.bxs
SCRIPT="/srv/basex/scripts/replacedb-${DB}.bxs"
echo "drop db $DB"               > $SCRIPT
echo "set attrindex off"         >> $SCRIPT
echo "set textindex off"         >> $SCRIPT
echo "set ftindex off"           >> $SCRIPT
echo "CREATE DB $DB"             >> $SCRIPT
echo "CREATE DB $DB $INPUTDIR"   >> $SCRIPT
echo "CREATE INDEX ATTRIBUTE"    >> $SCRIPT
echo "CREATE INDEX TEXT"         >> $SCRIPT
echo "OPTIMIZE ALL"              >> $SCRIPT
echo "open $DB"                  >> $SCRIPT
echo "flush"                     >> $SCRIPT
echo "info DB"                   >> $SCRIPT
echo "info index tag"            >> $SCRIPT
#echo "info index path"           >> $SCRIPT
echo "close"                     >> $SCRIPT
echo "list $DB"                  >> $SCRIPT

echo ""
echo "-- script: $SCRIPT"
cat $SCRIPT

cd /srv/basex/basex
echo ""
echo "-- running bin/basexclient -c $SCRIPT"
# put your credentials into your /srv/basex/basex/.basex file
sudo su fas --command "bin/basexclient -c $SCRIPT "


