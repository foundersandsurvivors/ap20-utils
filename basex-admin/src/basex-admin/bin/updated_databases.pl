#!/usr/bin/perl -s

# updated_databases.pl : look for update semaphore files in /data/bx/xml and recreate those databases

print "##============================= $0 at ".`date`;
$BXSOURCE = "/data/bx/xml";
$LOG = "/srv/basex/logs/updated_databases.pl.log";

my @dbs = databases_to_update($BXSOURCE);

foreach (@dbs) {
    $dbname = $_;
    $semfile = ".updated_$dbname";
    print "\n#################################### found $semfile UPDATING[$dbname]\n";
    print "# Contents $BXSOURCE/$dbname:\n";
    system("ls -la $BXSOURCE/$dbname");
    print "\n-- /srv/basex/bin/dbload-from-xml.sh $dbname >> $LOG\n" ;
    $rc = system("/srv/basex/bin/dbload-from-xml.sh $dbname >> $LOG");
    print "-- rc[$rc]\n";
    $boo = "+++yay+++"; 
    if ($rc) { $boo = "###BOO###"; }
    else {
       system("curl -g 'http://admin:admin\@localhost:8984/rest/$dbname?command=info%20db' >> $LOG 2>/dev/null");
    }
    $msg = "== rc[$rc] $boo $dbname at `date`\n";
    # remove the semaphote 
    system("rm $BXSOURCE/$semfile;echo $msg >> $LOG");
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


