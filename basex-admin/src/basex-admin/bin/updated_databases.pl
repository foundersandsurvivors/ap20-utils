#!/usr/bin/perl -s

# updated_databases.pl : look for update semaphore files in $BASEX_XML and recreate those databases

$BASEX_XML = $ENV{'BASEX_XML'} || die "Need to set environment: BASEX_XML";
$BASEX_ADMIN = $ENV{'BASEX_ADMIN'} || die "Need to set environment: BASEX_ADMIN";
$BASEX_REST = $ENV{'BASEX_REST'} || die "Need to set environment: BASEX_REST";

print "##============================= $0 at ".`date`;
$LOG = "$BASEX_ADMIN/logs/updated_databases.pl.log";

my @dbs = databases_to_update($BASEX_XML);

foreach (@dbs) {
    $dbname = $_;
    $semfile = ".updated_$dbname";
    print "\n#################################### found $semfile UPDATING[$dbname]\n";
    print "# Contents $BASEX_XML/$dbname:\n";
    system("ls -la $BASEX_XML/$dbname");
    print "\n-- $BASEX_ADMIN/bin/dbload-from-xml.sh $dbname >> $LOG\n" ;
    $rc = system("$BASEX_ADMIN/bin/dbload-from-xml.sh $dbname >> $LOG");
    print "-- rc[$rc]\n";
    $boo = "+++yay+++"; 
    if ($rc) { $boo = "###BOO###"; }
    else {
       system("curl -g '$BASEX_REST/$dbname?command=info%20db' >> $LOG 2>/dev/null");
    }
    $msg = "== rc[$rc] $boo $dbname at `date`\n";
    # remove the semaphote 
    system("rm $BASEX_XML/$semfile;echo $msg >> $LOG");
}

exit 0;

#----------------------------------------------------------------
sub databases_to_update {
  my $dir = shift;
  my @f;
  opendir(DIR, $dir) or die $!;
  while (my $file = readdir(DIR)) {
     if ($file =~ m/^\.updated_(.+)/) {
         push (@f, $1);
     }
     #next if ( -d "$dir/$file" ); # we do NOT want directories
     #push (@f,$file);
     #print "..filesInDir: $file\n" if $loud;
  }
  closedir(DIR);
  return @f;
}


