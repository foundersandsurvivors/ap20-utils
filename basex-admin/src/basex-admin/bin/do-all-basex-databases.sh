#!/bin/bash

if [ "x$BASEX_XML"    == "x" ]; then echo "Need to set environment: BASEX_XML"; exit 1; fi
if [ "x$BASEX_ADMIN"  == "x" ]; then echo "Need to set environment: BASEX_ADMIN"; exit 1; fi
if [ "x$BASEX_DISTRO" == "x" ]; then echo "Need to set environment: BASEX_DISTRO"; exit 1; fi
if [ "x$BASEX_DATABASE" == "x" ]; then echo "Need to set environment: BASEX_DATABASE"; exit 1; fi
if [ "x$BASEX_REST" == "x" ]; then echo "Need to set environment: BASEX_REST"; exit 1; fi

function basex_list () {
  BXCOMMAND=$1
  case "$HOSTNAME" in
     devfas)
        URL='http://devfas:8984/rest/'
        ;;
     *)
        URL="$BASEX_REST/"
        ;;
  esac
  # get list of dbs via rest and some perl
  CMD="wget -O /tmp/$$ '$URL?command=list'" 
  CMD="curl -g '$URL?command=list' > /tmp/$$" 
  echo "-- CMD[$CMD] start:"
  wget -O /tmp/$$ $URL'?command=list'

  ##wget -O /tmp/$$ 'http://klaatu:8984/rest/?command=list'
  
  echo "#----------------------------------- $URL :"
  if ! [[ -n /tmp/$$ ]]; then echo "##ERROR## CMD[$CMD] failed to generate output"; exit 1; fi
  echo "............................. CMD[$CMD] start:"
  cat /tmp/$$
  echo "............................. CMD[$CMD] END"
  echo "# perl ......................................................"
  ALLDATABASES=`perl -ne 'print "$1\n" if m/^(\S+)\s+\d+\s+\d+/;' /tmp/$$`
  rm /tmp/$$

  OUT="/tmp/bx.commands.$USER"
  echo "" > $OUT
  if [ "$BXCOMMAND" == "cleanup" ]; then
      echo '#!/bin/bash' > $OUT
      echo "# checking $BASEX_DISTRO/data for old zips" >> $OUT
      if ! [[ "$BASEX_DATABASE" == "$BASEX_DISTRO/data" ]]; then
           echo "# checking $BASEX_DATABASE for old zips" >> $OUT
      fi
  fi
  echo ""
  echo "-- Generating $BXCOMMAND  for all basex databases on $HOSTNAME "
  for DB in $ALLDATABASES
  do
     case "$BXCOMMAND" in
        backup)
            echo "create backup $DB" >> $OUT
            ;;
        export)
            echo "execute \"open $DB; export export/$DB; close\"" >> $OUT
            ;;
        reindex)
            echo "execute \"open $DB; optimize; close\"" >> $OUT
            ;;
        cleanup)
            # remove all but the latest backups
            # in normal basex data location
            for F in `find $BASEX_DISTRO/data -iname "$DB*.zip" -mtime +1 -exec ls {} \; | head --lines=-1`
            do
               echo "sudo rm -rf $F" >> $OUT
            done
            # in our basex database location if its different
            if ! [[ "$BASEX_DATABASE" == "$BASEX_DISTRO/data" ]]; then
               for F in `find $BASEX_DATABASE -iname "$DB*.zip" -mtime +1 -exec ls {} \; | head --lines=-1`
               do
                   echo "sudo rm -rf $F" >> $OUT
               done
            fi
            ;;
        info)
            echo "execute \"open $DB; info DB; close\"" >> $OUT
            ;;
        *)
            echo "unsupported BXCOMMAND[$BXCOMMAND]"
            echo "$0 info|reindex|export|backup|cleanup"
            exit 1
            ;;
     esac
  done

  case "$BXCOMMAND" in
        cleanup)
                 echo "# files to remove listed in $OUT"
                 chmod 774 $OUT
                 cat $OUT
                 exit 0
                 ;;
        *)
            echo "# See commands in $OUT"
            ls -la $OUT
            cat $OUT
            ;;
  esac

  echo "# See commands in $OUT"
  ls -la $OUT
  cat $OUT

}

basex_list $1
if [ "$2" = "do" ]; then
    echo "#== running bin/basexclient -c /tmp/bx.commands.$USER"
    cd $BASEX_DISTRO
    ./bin/basexclient -c /tmp/bx.commands.$USER
else
    echo "As fas; cd $BASEX_DISTRO ; bin/basexclient -c /tmp/bx.commands.$USER"
fi
rm /tmp/$$

exit 0
