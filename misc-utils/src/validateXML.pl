#!/usr/bin/perl -s

# validate xml with libxml; it does xml:id checking

use encoding "utf8";
use XML::LibXML;
use XML::LibXML::XPathContext;

my $f = $ARGV[0];
die "$0 -xmlid file  # Validate a file, supply an xml:id if asked\n" unless $f;

# if we have ids, convert to xml:ids
my $con = '';
if ($xmlid) {
  open(F,$f); while (<F>) { s/ id="/ xml:id="/g; $con .= $_; } close(F);
  my $doc = XML::LibXML->new->parse_string($con);
}
else {
  my $doc = XML::LibXML->new->parse_file($f);
}
# it dies here if errors
print "# $0 normal eoj. $f is valid xml.\n";
exit 0;








