#!/bin/bash

# dbload-from-xml.sh: load a basex database from a directory of xml files (dirname=dbname)
# for "rsync", your .ssh/config should define "xmlfiles-server" as the host serving master copies of /data/bx/xml

if [ "x$BASEX_XML"    == "x" ]; then echo "Need to set environment: BASEX_XML"; exit 1; fi
if [ "x$BASEX_USER"   == "x" ]; then echo "Need to set environment: BASEX_USER"; exit 1; fi
if [ "x$BASEX_ADMIN"  == "x" ]; then echo "Need to set environment: BASEX_ADMIN"; exit 1; fi
if [ "x$BASEX_DISTRO" == "x" ]; then echo "Need to set environment: BASEX_DISTRO"; exit 1; fi
KEEP_NEWER_HERE="--update"
DB="$1"
RSYNC="$2"
INPUTDIR="$BASEX_XML/$DB"
XMLFILES_RSYNC="xmlfiles-server:$BASEX_XML" # as per your .ssh/config file
KLAATU_SRV_PATH="/srv/basex/basex"
if [[ "$HOSTNAME" == "klaatu" ]]; then
   # klaatu syncs to dev and on dev, xml data is in the basex distro; see also the .ssh/config file
   XMLFILES_RSYNC="xmlfiles-server:$KLAATU_SRV_PATH" 
fi

if [ "$DB" == "" ]; then
   echo "usage: $0 database [rsync]"
   echo "      If rsync is specified, xml will be rsynced from $XMLFILES_RSYNC"
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
    # try --itemize-changes to see what needs to be changed
    rsync_opts="--itemize-changes -vax --delete $KEEP_NEWER_HERE"
    rsync -n --stats $rsync_opts $XMLFILES_RSYNC/$DB $BASEX_XML > /tmp/$$ 2>&1
    NO_CHANGES=`grep "Number of files transferred: 0" /tmp/$$`
    rm /tmp/$$
    # if no changes on rsync, nothing to do
    if [[ "$NO_CHANGES" == "" ]]; then
        echo "-- running: rsync $rsync_opts $XMLFILES_RSYNC/$DB $BASEX_XML"
        rsync $rsync_opts $XMLFILES_RSYNC/$DB $BASEX_XML
        touch $BASEX_XML/$DB
    else
        echo "-- No changes: [$NO_CHANGES] from $XMLFILES_RSYNC/$DB"
        echo "-- If you still want to force creation, run again without rsync."
        echo "# eoj. ($DB unchanged)"
        exit 0
    fi
    echo "-- running: rsync $rsync_opts $XMLFILES_RSYNC/$DB $BASEX_XML"
    rsync $rsync_opts $XMLFILES_RSYNC/$DB $BASEX_XML
    touch $BASEX_XML/$DB
fi

FTIDX=''
if [[ $DB =~ FT$ ]] ; then FTIDX="yes"; fi

# Create .bxs command files in $BASEX_ADMIN/scripts/replacedb-vjs.bxs
SCRIPT="$BASEX_ADMIN/scripts/replacedb-${DB}.bxs"
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

echo ""
# ensure correct permissions and credentials inside the .basex file in the basex distro dir
cd $BASEX_DISTRO
echo "-- running bin/basexclient -c $SCRIPT"
sudo su $BASEX_USER --command "bin/basexclient -c $SCRIPT"


