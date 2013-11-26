#!/usr/bin/perl 

# perl script to send an email (our hosts are not allowed to send mail externally)

require "myEmailer.pl";
my $msg = $ARGV[2];
if ( $msg && -f $ARGV[2] ) {
   # if its a filename, read it
   $msg = '';
   open (F,$ARGV[2]) || die "Failed to open F[$ARGV[2]] [$!]\n"; while (<F>) { $msg .= $_; } close(F);
}
    
myEmailer( $ARGV[0],  $ARGV[1],  $msg ) if ($ARGV[0] && $ARGV[1] && $ARGV[2]);

exit 0;
