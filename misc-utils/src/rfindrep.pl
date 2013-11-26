#!/usr/bin/perl
##############################################################################
# http://www.levindustries.com/xterm/scripts/usr-local-bin-rfindrep
##############################################################################
# rfindrep.pl (does recursive find and optional replace of a grep string)
#
# Documentation available from:
# <URL:http://www.its.unimelb.edu.au:801/cwis/tools/rfindrep/rfindrep.html>
# 
# Sandra Silcot            
#     Info.Sys.Dev, ITS, Univ of Melbourne, Parkville, VIC, Australia, 3052.
#     Email: ssilcot@www.unimelb.edu.au  http://www.unimelb.edu.au/~ssilcot/
#
# Version history:
#     26  Nov 1013  V2.1 Removed newgetopt.pl; use GetOptions now.
#     18 Sept 1995  V2.0 Single lines only and speed up by file globbing.
#                        Added -t and -s options.
#     14 July 1995  V1.1 General cleanup, html mode and better interface.
#     Sept 1994     V1.0 Initial version
#
# Thanks and acknowledgment is due to
# Paul Anderson, LFCS, Dept. of Computer Science, University of Edinburgh    
# for posting a skeletal GREP program to the net on which some of this
# code was based.
#
# Freely distributed for any purpose under the Perl Artistic Licence.
##############################################################################
###################################################### CUSTOMISE DEFAULTS HERE
##############################################################################
## Unix and Mac users should customise these:
$default_context = 30;  # default for num chars to print either side of match
                        # use -1 for no context
$default_filenamematch = '\.xq$'; # default filename match
$default_outstyle_for_find              = "report";
if ($MacPerl'Version =~ /Application$/) {
    # Macintosh default filenames
    $default_outfile_for_findonly_report    = "Zen:rfindrep-find-output.txt";
    $default_outfile_for_findonly_html      = "Zen:rfindrep-find-output.html";
    $default_outfile_for_replace            = "Zen:rfindrep-replace-output.html";
} else {
    # Unix default filenames
    $default_outfile_for_findonly_report    = "$ENV{'HOME'}/rfr-find-output.txt";
    $default_outfile_for_findonly_html      = "$ENV{'HOME'}/rfr-find-output.html";
    $default_outfile_for_replace            = "$ENV{'HOME'}/rfr-replace-output.html";
}
## These apply for Mac users only:
$machelp = 1;           # will supply help for each dialog for mac users
$MacCreator = 'QED1';   # on macs, set creator of text files to Qued/M

# if you change any defaults, note it in the usage info
&define_usage_info; # this just inits the usageinfo string

##############################################################################
########################################################### END CUSTOMISATIONS
##############################################################################
# nothing needs to be changed below this
##############################################################################
$debug = 0;
$version = '2.1';
# ---------------------------------------------------------- get command line options
# -f findpattern, -r replacepattern, -m namefilterpattern,
# -o filename, -l list filenames only, -s outputstyle (report|html)
# -k no metachars (ie. literal interpretation - escape all metas)
# -t test mode (do not make updates in replace mode)

$mac_options_prompt = "Options? (-m PATTERN -k -i -t -h -v N -l -s -o file )";
@options = ("f=s","r:s","m=s","o:s","i","t","d","l","k","s","h","v:n");

&get_commandline_options;

# ---------------------------------------------------------- process options
&process_and_display_options;

# After the processing above:
#     - the search  pattern is in $changeFrom
#     - $opt_r is true if replacement to be made and 
#              the replace pattern is in $changeTo (this is empty if no replacement)
#     - $opt_m contains the pattern match for filename selection
#     - $opt_v contains the number of chars of context to print (-1 means none)
#     - $opt_i contains 'i' if case INsensistive and empty if case sensitive
#     - $output_style contains the type of output (report | html)
#     - $opt_o contains a filename to print output to, or empty if to STDOUT
#     - $listfilesonly is "yes" if user specified $opt_l switch else "no"
#     - $debug is true (1) if user specified $opt_d switch
#     - $testmode is true (1) if user specified $opt_t switch

# ------------------------------------------------ calc program to be eval'ed
$theProgram = &generate_the_program;

# ---------------------------------------------------- Main loop to
# ---------------------------------------------------- process dirs and files
# ---------------------------------------------------- 
$n = $tot = $nfp = $nff = $nfr = $nfmod = $nmod = 0;

# slurp whole files into ram and enable multiline matches
#       This means we will read whole files into a variable
#       we won't be able to know what line we are doing but
#       it goes much much faster this way
undef($/);
# no longer supported. $* = 1; # multiline matching

print STDERR "=========================================\n$INPUT\n" if $opt_o;
($time_before_scan,$tmp1,$tmp2,$tmp3) = times;

foreach $dirName (@ARGV) {
    print STDERR "\nSearching for [$changeFrom] in $dirName\n\n" if $debug;
    if (-d $dirName) { &DoDir($dirName); }
    else {
        # its not a dir, see if its a file
        if (-T $dirName) { &scanfile($dirName); }
        else { print STDERR "INPUT ERROR: Textfile/Dir does not exist: [$dirName]\n"; }
    }
}

# generate control totals in a variable
($time_after_scan,$tmp1,$tmp2,$tmp3) = times;
$secs = $time_after_scan - $time_before_scan;
$CONTROLS  .= "\nSummary\n=======\n";
if ($opt_r) {
    $CONTROLS .= "Total of $nmod matches changed from [$changeFrom] to [$changeTo] in $nfmod files\n";
    if ($testmode) {
        $CONTROLS .= "TESTMODE only - updates were not made on disk.\n";
    }
} else {
    $CONTROLS .= "Total of $tot matches of [$changeFrom] found in $nff files\n";
}
$CONTROLS .=  "$nfp filenames matching [$opt_m] ".
              "selected from $nfr recursively found.\n";
$TIMING = "Scanning $nfp files took " . sprintf("%8.2f",$secs) . " seconds.";

# ---------------------------------------------------- redirect std output to file?
if ($opt_o) {  
    if ( open (STDOUT,">$opt_o") ) {
        # output successfully directed to a file named in $opt_o
        print STDERR "$CONTROLS\n"; # so we still see this online
        print STDERR "Full output written to [$opt_o]\n";
        $wrote_to_file = 1;
    } else {
        # output successfully directed to a file named in $opt_o
        print STDERR "##ERROR## Failed to open output file $opt_o\n".
                     "          Output will be sent to console\n";
    }
} 
# ---------------------------------------------------- print output
($head,$foot) = &get_output_wrappers;
print "$head\n";
# sort the @OUTPUT array by matchcount sequence
foreach $rank (sort bymatchfreq keys %matchcount) {
    @outlines = split(/\s/,$matchcount{$rank});
    foreach (@outlines) {print "$OUTPUT[$_]\n";}
}
print "$foot\n";
if ($wrote_to_file) {
    close(STDOUT);
    if ($mac) { &MacPerl'SetFileInfo("$MacCreator", "TEXT", $opt_o); }
    if ($ENV{COMMANDLINE}) {
        &MacPerl'Reply("$CONTROLS\nFull output written to [$opt_o]\n");
    }
}
print STDERR "$TIMING\n========================================= fin\n" if $opt_o;
exit;

################################################################### 
########################### SUBROUTINES ########################### 
################################################################### 
# ------------------------------------------------- bymatchfreq
# sort routine for ranking output sequence
sub bymatchfreq { $b <=> $a; }

# ------------------------------------------------- calc_url
# Only called for html output
# Returns a file URL for the passed filename
#
sub calc_url {
    local($theURL) =@_;
    if ($mac) { $theURL =~ s|:|/|g; } # convert mac filenames to url form
    ####$URLBASE = "Zen/WIP/";  # path to the server home in Unix form
    $SERVERURL = "file:///";  # path to the server home
    ####$URLBASE = "Zen/WIP/";  # path to the server home in Unix form
    ####$SERVERURL = "http://server.at.Zen.WIP/";  # path to the server home
    $theURL =~ s|^$URLBASE|$SERVERURL|o;    
    return($theURL);
}
# ------------------------------------------------- scanfile
# All the work of looking for matches 
# and gathering the output is done here
#
sub scanfile {
    local($f)=@_;
    $nfr++;
    # check for filename match
    if ( $opt_m && !($f =~ m/$opt_m/) ) {
        print STDERR "Filename pattern match [$opt_m] excluded $f\n" if $debug;
        return(0);
    }  
    $nfp++;
    open(FILE,"<$f") || die "can't open for read $f: $!\n";
    $nfoundhere = 0; $data = $OUT = "";
    # we process the file as a glob (can't get lines but MUCH faster)
    $_ = <FILE>;
    close(FILE);

    eval "$theProgram";
    if ($@) {
        die "Error from theProgram eval=[$@]\ntheProgram=[$theProgram]\n";
    } else {
        print STDERR "Successful exec of\n$theProgram\n" if $debug;
    }
    #
    # after theProgram executes:
    #    - $nfoundhere contains the number of matches
    #    - $OUT contains formatted output
    #

    if ($nfoundhere) {
        $tot += $nfoundhere;             # total matches
        $nff++;                          # num files with matches
        $key = $nff - 1;                 # array key of this files output
        # append key of output to matchcount assoc array keyed on count
        # we use this for ranking later
        $matchcount{$nfoundhere}.= $key." "; 
        # here is where we store the output for this file
        $OUTPUT[$key] = $OUT;     
        print STDERR "Found $nfoundhere in $f\n";
    }
    else {
        print STDERR "None found in $f\n";
    }
    return($nfoundhere);
}

sub DoDir {
    local($dir)=@_;
    print STDERR "********** doing $dir\n" if $debug;
    opendir(DH,$dir) || die "Can't open $dir: $!\n";
    local(@files) = grep(!/^\./,readdir(DH));   # ignore unix dot files
    print STDERR "files=@files\n" if $debug;
    closedir(DH);
    local($f);
    foreach $f (@files) {
        $fullName="$dir$pd$f";
        print STDERR "********** testing $fullName\n" if $debug;
        if (-d "$fullName$pd") {
            print STDERR "********** its a dir: dodir([$fullName])\n" if $debug;
            &DoDir("$fullName")
        } 
        else {
            print STDERR "********** its NOT a dir\n" if $debug;
            if (-T $fullName) { 
                print STDERR "********** its PASSED THE T TEST\n" if $debug;
                if ( &scanfile($fullName) && $r ) {&replaceit($fullName);}
            }
        }
    }
}
# ------------------------------------------------ generate_the_program
# return the program code to be eval'ed later
# After each eval:
#    - $nfoundhere contains the number of matches found in the file
#    - $OUT contains the output for the matches

sub generate_the_program {
    local($theProgram) = '';
    if ( $opt_r ) {
        
        # Replacement mode - generate the program for html output
        # we will always show whole lines

        $theProgram = <<THEPROGRAMFORHTML;
        \$data = \$_;  # save a copy of the file data for changes
        \$data =~ s%$changeFrom%$changeTo%g$opt_i;
        if ( \$data ne \$_ ) {
             print STDERR "got \$nchanges changes\\n" if $debug;
             # there are changes now in $data to be written to file 
             unless ("$testmode") {
                 open(FILE,">\$f") || die "can't open for writing \$f: \$!\\n";  
                 print FILE "\$data";
                 close(FILE);
                 if ("$mac") {\&MacPerl'SetFileInfo("$MacCreator", "TEXT", \$f);}
             }
             # change again in $_ for html output
             \$nfoundhere = s%$changeFrom%\\0$changeTo\\0%g$opt_i;
             print STDERR "nfoundhere=[\$nfoundhere]\\n" if $debug;
             \$nmod += \$nfoundhere;
             \$nfmod++;
             # get all the matched lines (these now contain nullchars \0)
             (\@matches) = m%^(.*\\0.*)\$%g;
             print STDERR "matches=[\$#matches]\\nfirstafter null=[\$matches[0]]\\n" if $debug;
             # escape html for display in browser
             grep(s%<%\&lt;%g,\@matches);
             grep(s%>%\&gt;%g,\@matches);
             # bold the matches
             grep(s%\\0([^\\0]+)\\0%<b>\$1</b>%g,\@matches);
             print STDERR "firstafter bold=[\$matches[0]]\\n" if $debug;
             # get the url
             \$url = \&calc_url(\$f);
             print STDERR "url=[\$url]\\n" if $debug;
             \$nlines = \$#matches + 1;
             \$OUT="<p>File: <A HREF=\\"\$url\\">\$f</A><br>\\n".
                   "\$nlines lines contain \$nfoundhere matches of [\$changeFrom] ".
                   "which were changed to [\$changeTo]</p>\\n";
             if ("$listfilesonly" eq "no") {
                 # we only display the matched lines if opt_l was not specified
                 \$OUT .= "<ul>\\n<li>" . join("\\n<li>",\@matches) . "\\n</ul>\\n";
             }
        }
THEPROGRAMFORHTML
    }
    elsif ($output_style eq 'report') {
        
        # generate the program for a plain report

        if ($opt_v > 0) {

            # generate the program for context

            $theProgram = <<THEPROGRAMWITHCONTEXT;
            while ( m%.{0,$opt_v}$changeFrom%$opt_i ) {
                \$nfoundhere++;
                \$theMatch = \$&;
                if ($opt_v > 0) { (\$after) = \$' =~ m%(.{0,$opt_v})%; }
                else            {  \$after = ''; }
                \$OUT .= "*match* \$theMatch\$after\\n";
                \$_ = \$'; # set the line to after the match to prevent infinite loop
            }
THEPROGRAMWITHCONTEXT
        }
        else {

            # generate the program for NO context

            $theProgram = <<THEPROGRAMWITHNOCONTEXT;
            (\@matches) = m%($changeFrom)%g$opt_i;
            if (\$#matches >= 0) {
                \$nfoundhere = \$#matches + 1;
                \$OUT = "*match* " . join("\\n*match* ",\@matches);
            }
THEPROGRAMWITHNOCONTEXT
        }

        # now tack on the output processing
        $theProgram .= <<OUTPUTFORFINDS;
        # output processing
        if (\$nfoundhere) {
            if ("$listfilesonly" eq "yes") {
                # we don't display the matched lines if opt_l was specified
                \$OUT = "------- \$nfoundhere matches of [\$changeFrom] ".
                        "found in \$f\\n";
            } else {
                # display the matched lines
                \$OUT = "------- \$nfoundhere matches of [\$changeFrom] ".
                        "found in \$f\\n" . \$OUT . "\\n";
            }
        }
OUTPUTFORFINDS
    }
    elsif ($output_style eq 'html') {

        # generate html output for a find (always show whole lines)

        $theProgram = <<THEPROGRAMFORHTMLFINDONLY;
        # replace with itself
        \$nfoundhere = s%$changeFrom%\\0\$&\\0%g$opt_i;
        if ( \$nfoundhere ) {
             print STDERR "got \$nfoundhere matches\\n" if $debug;
             # get all the matched lines (these now contain nullchars \0)
             (\@matches) = m%^(.*\\0.*)\$%g;
             print STDERR "matches=[\$#matches]\\nfirstafter null=[\$matches[0]]\\n" if $debug;
             # escape html for display in browser
             grep(s%<%\&lt;%g,\@matches);
             grep(s%>%\&gt;%g,\@matches);
             # bold the matches
             grep(s%\\0([^\\0]+)\\0%<b>\$1</b>%g,\@matches);
             print STDERR "firstafter bold=[\$matches[0]]\\n" if $debug;
             # get the url
             \$url = \&calc_url(\$f);
             print STDERR "url=[\$url]\\n" if $debug;
             \$nlines = \$#matches + 1;
             \$OUT="<p>File: <A HREF=\\"\$url\\">\$f</A><br>\\n".
                   "\$nlines lines contain \$nfoundhere matches of [\$changeFrom]</p>\\n";
             if ("$listfilesonly" eq "no") {
                 # we only display the matched lines if opt_l was not specified
                 \$OUT .= "<ul>\\n<li>" . join("\\n<li>",\@matches) . "\\n</ul>\\n";
             }
        }
THEPROGRAMFORHTMLFINDONLY
    }
    else { die "Unknown output style [$output_style]"; }

    return($theProgram);
}

sub escape_backslashes {
    foreach (@_) { s/\\/@@@@@@@@/g; }
    return (@_);
}
sub putback_backslashes {
    foreach (@_) { s/@@@@@@@@/\\/g; }
    return (@_);
}
sub escape_metachars {
    local($str) = @_;
    $str =~ s%[\$\^\*\[\]\{\}\^\|\(\)\!\\]%\\$&%g;
    return($str);
}
# ------------------------------------------------- get_commandline_options
sub get_commandline_options {
# 
# do platform specific stuff in getting command line arguments
#
# we allow backslashes in strings so have to escape them or shellwords and
# ngetopt calls get stuffed up.
#
if($MacPerl'Version =~ /Application$/) {
    $pd = ':';
    $mac = 1;
    ($macdisk) = $0 =~ m/^([^:]+)/;
    require 'shellwords.pl';
    # do we have an environment ie. parms via applescript?
    if  ( $ENV{COMMANDLINE} ) {
        chop($ENV{'COMMANDLINE'});
        print STDERR "1. applscriptenvt=[$ENV{COMMANDLINE}]\n" if $debug;
        $switches = $ENV{'COMMANDLINE'};
        # escape backslashes in -m for shellwords to work properly
        $switches = &escape_backslashes($switches);
        @macswitches = &shellwords($switches);
        # putback backslashes and assign to argv
        @ARGV = &putback_backslashes(@macswitches);
    }
    else {
        # Files & dirs have been passed by drag and drop,
        # so retain them and prompt for options
        &show_mac_help(1) if $machelp;
        $switches = &MacPerl'Ask($mac_options_prompt);
        unless (defined($switches)) { print STDERR "You cancelled\n"; exit; }
        # see if we are in testmode
        if ( $switches =~ m%\-t% ) { $testmsg = 'TestReplace'; }
        else                       { $testmsg = 'Replace'; }
        # escape backslashes in -m for shellwords
        $switches = &escape_backslashes($switches);
        @macswitches = &shellwords($switches);
        &show_mac_help(2) if $machelp;
        while ( (!defined($changeFrom))  || ($changeFrom eq '') ) {
            $changeFrom = &MacPerl'Ask( 'Find pattern:' );
            unless (defined($changeFrom)) { print STDERR "You cancelled\n";exit;}
        }

        $tmp = &MacPerl'Answer("How do you wish to proceed?","Find","$testmsg","Cancel");
        if ( $tmp == 0 ) { print STDERR "You cancelled\n"; exit; }
        elsif ( $tmp == 1 ) {
            &show_mac_help(3) if $machelp;
            $changeTo   = &MacPerl'Ask( "$testmsg with? (empty for noreplace, NULL deletes):" );
            unless (defined($changeTo)) { print STDERR "You cancelled\n";exit;}
            if ($changeTo eq '') {
                undef($changeTo);
                &MacPerl'Answer("Info: No replace pattern specified\nWill proceed in find mode...","OK");
            } else { 
                $tmp2 = &MacPerl'Answer("Really $testmsg all \"$changeFrom\" with \"$changeTo\" ?","$testmsg","Cancel");
                if ( $tmp2 == 1 ) { push(@macswitches,'-f',$changeFrom,'-r',$changeTo,@ARGV); }
                else  { print STDERR "You cancelled\n"; exit; }
            }
        }
        elsif ( $tmp == 2 ) {   # no replacement
            undef($changeTo);
            push(@macswitches,'-f',$changeFrom,@ARGV);
        } 
        # escape backslashes and assign to argv
        @ARGV = &putback_backslashes(@macswitches);
    }
}
else {
    $pd = '/';
    $mac = 0;
}
@userenteredthis = @ARGV;
# ------------------------------------------------------------ parse
# parse command line options
# escape backslashes
@ARGV = &escape_backslashes(@ARGV);
#################require 'newgetopt.pl';  # use newgetopt library to parse the options
#################if (! &NGetOpt(@options)) {die "Error in command line"};
use Getopt::Long;
$result = GetOptions (@options);
# putback backslashes
($opt_f,$opt_r,$opt_m,@ARGV) = &putback_backslashes($opt_f,$opt_r,$opt_m,@ARGV);
# ---------------------------------------------------------- debugging info
if ($debug) {
	if ( defined($opt_f) ) { print STDERR "opt_f is defined and=[$opt_f]\n"; }
	if ( defined($opt_r) ) { print STDERR "opt_r is defined and=[$opt_r]\n"; }
	if ( defined($opt_m) ) { print STDERR "opt_m is defined and=[$opt_m]\n"; }
	if ( defined($opt_s) ) { print STDERR "opt_s is defined and=[$opt_s]\n"; }
	if ( defined($opt_o) ) { print STDERR "opt_o is defined and=[$opt_o]\n"; }
	if ( defined($opt_i) ) { print STDERR "opt_i is defined and=[$opt_i]\n"; }
	if ( defined($opt_d) ) { print STDERR "opt_d is defined and=[$opt_d]\n"; }
	if ( defined($opt_h) ) { print STDERR "opt_h is defined and=[$opt_h]\n"; }
	if ( defined($opt_v) ) { print STDERR "opt_v is defined and=[$opt_v]\n"; }
	if ( defined($opt_k) ) { print STDERR "opt_k is defined and=[$opt_k]\n"; }
}

0;
}
# ------------------------------------------------- process_and_display_options
# after process_and_display_options:
#     - the search  pattern is in $changeFrom
#     - the replace pattern is in $changeTo (this is empty if no replacement)
#     - $opt_m contains the pattern match for filename selection
#     - $opt_v contains the number of chars of context to print (-1 means none)
#     - $opt_i contains 'i' if case INsensistive and empty if case sensitive
#     - $output_style contains the type of output
#     - $opt_o contains a filename to print output to, or empty if to STDOUT
#     - $listfilesonly is "yes" if user specified $opt_l switch else "no"
#     - $debug is true (1) if user specified $opt_d switch
#     and options have been displayed
#
sub process_and_display_options {

    # ---------------------------------------------------------- process options

    # escape meta chars to force literal interp of pattern if -k

    if ($opt_k) { $changeFrom = &escape_metachars($opt_f); }
    else        { $changeFrom = $opt_f; }

    # erase found pattern if user specified NULL for replace pattern

    $changeTo   = $opt_r;
    $changeTo =~ s/^NULL$//;             
         
    # escape the delimiter for pattern match commands - we use %

    $changeFrom =~ s/%/\\%/g;
    $changeTo   =~ s/%/\\%/g;
         
    # filename pattern match setup

    if (! $opt_m) {$opt_m = $default_filenamematch;}
         
    # context display

    if (! $opt_v) { $opt_v = $default_context; }
    elsif ($opt_v < 0) {$opt_v = 0;}
         
    # case sensitive switch

    if ($opt_i) {$opt_i = "i";}
    else        {$opt_i = "";}
         
    # testmode
    if ($opt_r && defined($opt_t)) {$testmode = 1;}
         
    # output style - html if replacing, otherwise plain report

    if ($opt_r) {$output_style = 'html';}
    else        {
        # check for -s and reverse the default 
        if (defined($opt_s)) {
            if ($default_outstyle_for_find eq "report") {
                $output_style = 'html';
            } else {
                $output_style = 'report';
            }
        } else {
            $output_style = $default_outstyle_for_find;
        }
    }
         
    # output file - if defined but false, assign default

    if (defined($opt_o) && !$opt_o) { 
        if ($opt_r) { $opt_o = $default_outfile_for_replace; }
        else        { 
            if ($output_style eq 'html') { 
                $opt_o = $default_outfile_for_findonly_html; 
            } else { 
                $opt_o = $default_outfile_for_findonly_report; 
            } 
        }        
    }

$default_outstyle_for_find              = "report";

    # list filenames only

    if ($opt_l) {$listfilesonly = "yes";}
    else        {$listfilesonly = "no";}

    if ($opt_d)   {$debug = 1;}  # print program diagnostics to STDERR

    # ------------------------------------------------------------ display input
    if ($opt_r) { $replacemsg = "and replace with [$changeTo]"; }
    else        { $replacemsg = ""; }
        
    $INPUT = "rfindrep.pl V$version. You entered:\n".
             "rfindrep.pl @userenteredthis\n";
    if ($opt_k) {
        $INPUT .= "Find Literal=[$changeFrom] $replacemsg\n".
                   "     options: ";
    }
    else {
        $INPUT .= "Find Pattern=[$changeFrom] $replacemsg\n".
                  "     options: ";
    }
    $INPUT .=  "matchnames[$opt_m] " if $opt_m;
    $INPUT .=  "replace "            if $opt_r;
    $INPUT .=  "TESTMODE "           if $testmode;
    $INPUT .=  "case-insensitive "   if $opt_i;
    $INPUT .=  "listfiles "          if $opt_l;
    $INPUT .=  "context=$opt_v ";
    $INPUT .=  "outputstyle=$output_style \n";
    $INPUT .=  "Target files or dirs:\n       " . join ("\n       ",@ARGV)."\n";

    # ------------------------------------------------------------ error checking
    if (! $ARGV[0]) {
        print STDERR "$usageinfo";
        print STDERR "Command line error: No DirOrFileList specified - try again.\n\n";
        exit;
        }
    elsif (!$changeFrom) {
        print STDERR "Command line error: No findpattern specified - try again.\n\n";
        print STDERR "$usageinfo";
        exit;
        }
    elsif ($opt_h) {print STDERR "$usageinfo";} # user wants help

    1;
}

# ---------------------------------------------------- get_output_wrappers
# return a header and footer for the output
#
sub get_output_wrappers {
    local($HEADER,$FOOTER);
    # -------------------------------------------------------- html output
    if ( $output_style eq 'html' ) {
        # escape the find pattern for html display
        $find_display = $changeFrom;
        $find_display =~ s|<|&lt;|g;
        $find_display =~ s|>|&gt;|g;
        if ($opt_r) {
            $replace_display = $changeTo;
            $replace_display =~ s|<|&lt;|g;
            $replace_display =~ s|>|&gt;|g;
            $SUMMARYMSG = "Replaced $tot occurances of".
                          " \"$find_display\" with \"$replace_display\" ".
                          "in $nff files.";
        } else {
            $SUMMARYMSG = "Found $tot occurances of".
                          " \"$find_display\" in $nff files.";
        }
        # --------------------------------------- html header
        $HEADER = <<HEADER;
<html>
<head><title>RFindRep for query "$find_display"</title></head>
<body>
<h2>RFindRep results for query "$find_display"</h2>
<pre>$INPUT</pre>
<p><code><b>$SUMMARYMSG</b></code></p>
<pre>$TIMING</pre>
HEADER
        if ($opt_l) { 
            $HEADER .= "<p><b>Matched text not displayed.</b></p>\n"; 
        }
        # --------------------------------------- html footer
        $FOOTER = <<FOOTER;
<hr>
<pre>$CONTROLS</pre>
<hr>
<pre>Generated by: $0</pre>
</body></html>
FOOTER
    }
    # --------------------------------------------------------- normal output
    else {
        # --------------------------------------- normal header
        $HEADER = <<HEADER2;
=======================================================================
$INPUT
--------
Total of $tot occurances of "$changeFrom" found in $nff files.
$TIMING
--------
HEADER2
        if ($opt_l) { 
            $HEADER .= "Matched text not displayed.\n"; 
        }
        # --------------------------------------- normal footer
        $FOOTER = <<FOOTER2;
$CONTROLS
=======================================================================
FOOTER2
    }
    return($HEADER,$FOOTER);
}
# ------------------------------------------------ define_usage_info
# just return a string with the usage info

sub define_usage_info {
    $one = '$1';
    $usageinfo = <<USAGEINFO;
Script:   $0 $version

RFindRep: Perl script to recursively process contents of specified
          directories and/or files, finding text files containing a pattern 
          and optionally replacing the matches with a replace-string.

Usage: 
(find):    RFindRep [options] -f findpattern DirOrFileList...
(replace): RFindRep [options] -f findpattern -r replacepattern DirOrFileList...

Example:   RFindRep -i -f '(.+)<p>\$' -r '<p>\$1</p>\$' /cern/docs 

Notes: 
1. '%' is used as the search/replace delimiter. This char will
   be automatically escaped for you if it is part of your patterns.
2. Perl expressions expected - enter just as you would if writing Perl code.
3. To erase the found string, enter NULL for the replacepattern.
4. Options:
   -m pattern Match filenames with this pattern 
              (default [$default_filenamematch]).
   -k         No symbol in the find pattern is treated as a meta character
              (forces an exact literal interpretation). 
   -i         case Insensitive (default is case sensitive).
   -t         Replace in TEST mode (do not update disk).
   -h         show Help text.
   -v NNN     print NNN chars either side of match (default=$default_context).
   -l         (lowercase L) List only the files that contain a match.
   -s         for a find, switch output style from default=[$default_outstyle_for_find]
   -o outfile write output to a specified file. If outfile omitted defaults to:
              find report style: [$default_outfile_for_findonly_report]
              find html   style: [$default_outfile_for_findonly_html]
              replace:           [$default_outfile_for_replace]
   -d         debug mode (gives program diagnostics)

USAGEINFO
}
# ------------------------------------------------ show_mac_help
# display prompts for mac users in a window
#
sub show_mac_help {
    local($dialog) = @_;
    $help{'1'} = <<MACHELPTEXT1;
==============================================================
rfindrep will prompt with 3 dialogs:

1. OPTIONS
----------
-m pattern  filename match pattern, default=[$default_filenamematch]
-k          interpret find pattern as a literal string
-i          case insensitive, default is case sensitive
-t          Replace in TEST mode (do not update disk).
-h          write help to output
-v N        display N chars of context around matches, default=[$default_context]
            (enter '-v -1' for no context)
-l          (lowercase L) will display matching filenames only
-s          for a find, switch output style from default=[$default_outstyle_for_find]
-o outfile  write output to a specified file. If filename omitted, defaults are:
            find report style: [$default_outfile_for_findonly_report]
            find html   style: [$default_outfile_for_findonly_html]
            replace:           [$default_outfile_for_replace]

Key a return to enter your options...
MACHELPTEXT1
    $help{'2'} = <<MACHELPTEXT2;
2. FIND PATTERN
---------------
You can specify a Perl regular expression unless you use -k.
Each character matches itself, except for +?.*()[]{}|\

.      match any character except a return
(...)  groups a series of pattern elements to a single element
+      match the preceeding pattern element one or more times
?                                           zero or one times
*                                           zero or more times
{N,M}  min N and max M; {N} exactly N times; {N,} at least N times
^      matches at the start of a line
\$      matches at the end of a line
[...]  denotes a class of characters to match
[^...] negates the class
(...|...|...) matches one of the alternatives
\\w  matches an alphanumeric char (including "_"), \\W matches non-alphanumeric
\\b  matches word boundaries, \\B non-boundaries
\\s     match a whitespace character, \\S a non-whitespace
\\d     match a numeric, \\D a non-numeric
\\t     match a tab character
\\NNN   matches octal character NNN
\\w,\\s and \\d may be used within classes

Note: In rfindrep patterns cannot span lines.
Key a return to enter your find pattern...
MACHELPTEXT2
    $help{'3'} = <<MACHELPTEXT3;
3. REPLACE PATTERN
------------------
The find pattern is: $changeFrom

In the replace pattern, each character matches itself.

\\1...\\9 or \$1...\$9 refer to matched sub-expressions grouped 
                       with () within the find pattern
\$\&  refers to the entire found pattern


Key a return to enter your replace pattern...
MACHELPTEXT3
    open (MACHELP, "+>Dev:Console:Help for Mac rfindrep");
    select(MACHELP); $| = 1;
    print MACHELP "$help{$dialog}";
    $crap = <MACHELP>;  # user hits a return to continue here
    close (MACHELP);
    select(STDOUT); $| = 0;
    1;
}
