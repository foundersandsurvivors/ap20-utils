#!/bin/bash

# dbload-from-xml.sh: load a basex database from a directory of xml files (dirname=dbname)
# for "rsync", your .ssh/config should define "xmlfiles-server" as the host serving master copies of /data/bx/xml

DB="$1"
XMLLOC="/data/bx/xml"
RSYNC="$2"
INPUTDIR="$XMLLOC/$DB"
XMLFILES_RSYNC="xmlfiles-server:/data/bx/xml" # as per your .ssh/config file
if [[ "$HOSTNAME" == "klaatu" ]]; then
   # on dev, things are in a different place, as per klaatu's .ssh/config file
   XMLFILES_RSYNC="xmlfiles-server:/srv/basex/basex" 
fi

if [ "$DB" == "" ]; then
   echo "usage: $0 database [rsync] (If rsync specified, xml will be synced from $XMLFILES_RSYNC)"
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
    #echo "-- running rsync --delete from xmlfiles-server to $XMLLOC"
    #sudo rsync -vax --delete root@devfas:/srv/basex/basex/$DB $XMLLOC
    echo "-- running rsync --delete from $XMLFILES_RSYNC to $XMLLOC"
    rsync -vax --delete $XMLFILES_RSYNC/$DB $XMLLOC
    touch $XMLLOC/$DB
fi

FTIDX=''
if [[ $DB =~ FT$ ]] ; then FTIDX="yes"; fi

# Create .bxs command files in /srv/basex/scripts/replacedb-vjs.bxs
SCRIPT="/srv/basex/scripts/replacedb-${DB}.bxs"
echo "drop db $DB"               > $SCRIPT
echo "set attrindex off"         >> $SCRIPT
echo "set textindex off"         >> $SCRIPT
echo "set ftindex off"           >> $SCRIPT
echo "CREATE DB $DB"             >> $SCRIPT
echo "CREATE DB $DB $INPUTDIR"   >> $SCRIPT
echo "CREATE INDEX ATTRIBUTE"    >> $SCRIPT
if [ "$FTIDX" == "yes" ]; then
    echo "SET LANGUAGE EN"       >> $SCRIPT
    echo "SET STEMMING true"     >> $SCRIPT
    echo "SET CASESENS false"    >> $SCRIPT
    echo "CREATE INDEX FULLTEXT" >> $SCRIPT
else
    echo "CREATE INDEX TEXT"     >> $SCRIPT
fi
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
sudo su fas --command "bin/basexclient -c $SCRIPT -U admin -P admin"


