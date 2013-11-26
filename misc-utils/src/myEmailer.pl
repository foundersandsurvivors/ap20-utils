# usage: myEmailer.pl

use Mail::Sendmail;

my $domail = 1; # make this zero to debug

sub myEmailer {
    my $jobTitle = shift;
    my $title = shift;
    my $info = shift;

    my $hostname = `hostname`; chop($hostname);
    my $sysadmin_email = $ENV{SYSADMIN_EMAIL};
    my $smtp_host = ''; # default to localhost mta
    if ($ENV{SMTP_HOST}) { $smtp_host = $ENV{SMTP_HOST}; }
    my $from = 'fasadmin@founders-and-survivors.org';
    my %mail = ( To      => $sysadmin_email,
                 From    => $from,
                 Subject => "[$hostname] $title",
                 Message => "jobTitle[$jobTitle]\n\n$info"
         );
    if ($sysadmin_email) {
        if ($smtp_host) { $mail{'smtp'} = $smtp_host; }

        print "\n-- myEmailer:\n";
        if ($domail) {
            foreach (keys %mail) {
                print "dbg..[$_] [".$mail{$_}."]\n";
            }
            print "Mail $from sent to $sysadmin_email via[$smtp_host] t[$title] ...start\n";
            sendmail (%mail) or die $Mail::Sendmail::error;
            print "Mail ...done\n";

        }
        else {
            print "domail[$domail]..Mail from[$from] NOT sent to[$sysadmin_email] via[$smtp_host]: title[$title]\njobTitle[$jobTitle]\n\ninfo[$info]\n";
            foreach (keys %mail) {
                print "dbg..[$_] [".$mail{$_}."]\n";
            }
        }
    }
    else {
        print "##ERROR## myEmailer.pl Mail not sent.]\nPlease define environment variables for SYSADMIN_EMAIL (the to address) and optionally SMTP_HOST\n"
    }
    return;
}
1;
