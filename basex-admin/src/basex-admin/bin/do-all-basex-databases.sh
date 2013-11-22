#!/bin/bash

function basex_list () {
  BXCOMMAND=$1
  case "$HOSTNAME" in
     devfas)
        URL='http://devfas:8984/rest/'
        ;;
     klaatu)
        URL='http://localhost:8984/rest/'
        ;;
     smstest2)
        URL='http://localhost:8984/rest/'
        ;;
     y1)
        URL='http://localhost:8984/rest/'
        ;;
     *)
        echo "unsupported host HOSTNAME[$HOSTNAME]"
        exit 0
        ;;
  esac
  # get list of dbs via rest and some perl
  CMD="wget -O /tmp/$$ '$URL?command=list'" 
  echo "-- CMD[$CMD] start:"
  wget -O /tmp/$$ $URL'?command=list'

  ##wget -O /tmp/$$ 'http://klaatu:8984/rest/?command=list'
  
  echo "#----------------------------------- $URL :"
  ls -la /tmp/$$
  #cat /tmp/$$
  echo "# perl ......................................................"
  ALLDATABASES=`perl -ne 'print "$1\n" if m/^(\S+)\s+\d+\s+\d+/;' /tmp/$$`

  OUT="/tmp/bx.commands.$USER"
  echo "" > $OUT
  if [ "$BXCOMMAND" == "cleanup" ]; then
      echo '#!/bin/bash' > $OUT
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
            for F in `find /srv/basex/basex/data -iname "$DB*.zip" -mtime +1 -exec ls {} \; | head --lines=-1`
            do
               echo "sudo rm -rf $F" >> $OUT
            done
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
    /srv/basex/basex/bin/basexclient -c /tmp/bx.commands.$USER
else
    echo "As fas; cd /srv/basex/basex; bin/basexclient -c /tmp/bx.commands.$USER"
fi
