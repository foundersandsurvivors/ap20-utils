#!/bin/bash

DB=$1
if [[ "$DB" == "" ]]; then
   echo "Usage: $0 postgresqldatabasename"
   echo ""
   echo "Available postgresql databases are [psql -l]:"
   psql -l
   exit 1
fi

NOW=`date +"%Y-%m-%d_%T"`
echo $0 $*
echo "##============= $0 Exporting $DB xml $NOW"
echo ""
DIR="$DB/xml"

echo "== Generating list of $DB tablenames"

psql $DB -f list_tables.sql

COLLECTION_DOC="${DB}_collection.xml"
SCRIPT_PATH=$(cd `dirname ${0}`; pwd)
# keep previous run
if [ -d $DIR ]; then
   if [ -d "$DB.previous" ]; then
       rm -rf $DB.previous
   fi
   mv $DB $DB.previous
   echo "-- saved previous run to $DB.previous"
fi
mkdir -p $DIR
mv tablenames.txt $DB/tablenames.txt
SCRIPT_NAME=`basename $0`
echo "<collection key=\"$DB\" when=\"$NOW\" generated_by=\"$SCRIPT_PATH/$SCRIPT_NAME\" id=\"$COLLECTION_DOC\">" > $DB/$COLLECTION_DOC

TMP="/tmp/$$"
echo "\a" > $TMP
echo "\pset tuples_only" >> $TMP

echo "-- converting each table in $DB/tablenames.txt to xml ..."
for T in `cat $DB/tablenames.txt`
do
   OUT="$SCRIPT_PATH/$DIR/${T}.xml"
   # note the href here is relative to the collection doc path
   OUTURI="xml/${T}.xml"
   echo "  <doc href=\"$OUTURI\"/>" >> $DB/$COLLECTION_DOC

   # $TMP is the sql commands file
   echo "" >> $TMP
   echo "\o $OUT" >> $TMP
   ORDER_BY=""

   # add custom ordering for particular tables if required

   case $T in
      dead_children) 
         ORDER_BY="order by person_fk"
         ;; 
      event_citations) 
         ORDER_BY="order by event_fk, source_fk"
         ;; 
      linkage_roles) 
         ORDER_BY="order by role_id"
         ;; 
      participants) 
         ORDER_BY="order by person_fk, sort_order, event_fk"
         ;; 
      persons) 
         ORDER_BY="order by person_id"
         ;; 
      place_level_desc) 
         ORDER_BY="order by place_level_id"
         ;; 
      places) 
         ORDER_BY="order by place_id"
         ;; 
      relation_citations) 
         ORDER_BY="order by relation_fk,source_fk"
         ;; 
      relations) 
         ORDER_BY="order by relation_id"
         ;; 
      source_linkage) 
         ORDER_BY="order by source_fk, per_id"
         ;; 
      source_part_types) 
         ORDER_BY="order by part_type_id"
         ;; 
      sources) 
         ORDER_BY="order by source_id"
         ;; 
      sureties) 
         ORDER_BY="order by surety_id"
         ;; 
      tag_groups) 
         ORDER_BY="order by tag_group_id"
         ;; 
      tag_prepositions) 
         ORDER_BY="order by tag_fk,lang_code"
         ;; 
      tags) 
         ORDER_BY="order by tag_group_fk,tag_id"
         ;; 
      templates) 
         ORDER_BY="order by source_fk"
         ;; 
      user_settings) 
         ORDER_BY="order by username"
         ;; 
      *)
         ORDER_BY=""
         ;;
   esac
   echo "select query_to_xml('select * from $T $ORDER_BY',false,true,'');" >> $TMP
done
echo "</collection>" >> $DB/$COLLECTION_DOC

echo "== See saxon collection at: $DB/$COLLECTION_DOC ":
echo ""
cat $DB/$COLLECTION_DOC

echo ""
echo "== Generating xml for each table ":
echo ""
psql $DB -f $TMP

echo ""
echo "== Remove crud ":
echo ""
for T in `cat $DB/tablenames.txt`
do
   OUT="$SCRIPT_PATH/$DIR/${T}.xml"
   echo "<table name=\"${T}\" id=\"${DB}.$T\" when=\"$NOW\" generated_by=\"$SCRIPT_PATH/$SCRIPT_NAME\">" > $TMP
   perl -pe 's/<row[^\<]+/\<'$T'\>/; s/<\/row/\<\/'$T'/;' $OUT >> $TMP
   echo "</table>" >> $TMP
   mv $TMP $OUT
done
ls -la $DIR

OUT="$DB/${DB}_database.xml"
echo ""
echo "== make $OUT (all in one xml file -- may need large amount of memory)"
echo ""
if [ "$SEEQ" == "" ]; then
   SEEQ='java net.sf.saxon.Query -qversion:1.1'
   echo "-- Using this command for Saxon Xquery (set SEEQ envt variable to modify): [$SEEQ]"
fi
$SEEQ -qs:'<database name="'$DB'">{for $doc in collection("'$DB/$DB'_collection.xml") return $doc}</database>' -o:$TMP
echo "-- [$?] from saxon making $OUT"
perl -ne 'print unless m/^\n$/;' $TMP > $OUT

echo "-- done: single xml files per table located in in $DIR"
echo "-- done: all in one xml file for database [$DB] located in in $OUT"
ls -la $OUT
md5sum $OUT > $OUT.md5
echo "-- md5sum:"
cat $OUT.md5
echo "#== $0 normal eoj"
exit 0

