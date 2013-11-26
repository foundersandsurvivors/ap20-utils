ap20-utils/misc-tellSysAdmin
============================

About
-----

Some general utilities typically for /usr/local/bin:
* rfindrep.pl: recursive find/replace
* validateXML.pl: validate an xml file
* tellSysadmin.pl: send email to address in envt `SYSADMIN_EMAIL`
* perl-installed-modules-list.sh: list cpan modules

./rfindrep.pl
-------------

A recursive find and replace utility (perl).

Usage:
<pre>
 ./rfindrep.pl -h
Script:   ./rfindrep.pl

RFindRep: Perl script to recursively process contents of specified
          directories and/or files, finding text files containing a pattern
          and optionally replacing the matches with a replace-string.

Usage:
(find):    RFindRep [options] -f findpattern DirOrFileList...
(replace): RFindRep [options] -f findpattern -r replacepattern DirOrFileList...

Example:   RFindRep -i -f '(.+)<p>$' -r '<p>$1</p>$' /cern/docs

Notes:
1. '%' is used as the search/replace delimiter. This char will
   be automatically escaped for you if it is part of your patterns.
2. Perl expressions expected - enter just as you would if writing Perl code.
3. To erase the found string, enter NULL for the replacepattern.
4. Options:
   -m pattern Match filenames with this pattern
              (default [\.xq$]).
   -k         No symbol in the find pattern is treated as a meta character
              (forces an exact literal interpretation).
   -i         case Insensitive (default is case sensitive).
   -t         Replace in TEST mode (do not update disk).
   -h         show Help text.
   -v NNN     print NNN chars either side of match (default=30).
   -l         (lowercase L) List only the files that contain a match.
   -s         for a find, switch output style from default=[report]
   -o outfile write output to a specified file. If outfile omitted defaults to:
              find report style: [/home/ubuntu/rfr-find-output.txt]
              find html   style: [/home/ubuntu/rfr-find-output.html]
              replace:           [/home/ubuntu/rfr-replace-output.html]
   -d         debug mode (gives program diagnostics)
</pre>

./validateXML.pl
----------------

Uses perl's XML::LibXML to validate an xml file. Zero return code if the xml is valid.

Usage example:
<pre>
./validateXML.pl /data/bx/xml/vjs/vjs_conf.xml
# ./validateXML.pl normal eoj. /data/bx/xml/vjs/vjs_conf.xml is valid xml.
</pre>


./tellSysadmin.pl
-----------------

Perl utility script for sending email to a system administrator using a local MTA or an external smtp host.

You need to:
* install the perl CPAN module: `Mail::Sendmail`.
* define environment variable `SYSADMIN_EMAIL` defining the mail address to which mail will be sent
* if NOT using a local MTA, define environment variable `SMTP_HOST` defining the name of the smtp host used

Usage:
<pre>
./tellSysadmin.pl 1 2 3

-- myEmailer:
domail[0]..Mail from[ubuntu@smstest2] NOT sent to[johndoe@gmail.com: title[2]
jobTitle[1]

info[3]
</pre>

Where:
* environment variable `SYSADMIN_EMAIL`=johndoe@gmail.com
* "1" is a brief job synopsis/source which appears as the mail subect line
* "2" appears at top of the message
* "3" is the rest of the message; if its a filename, the file is copied and included in the message

Requires a library myEmailer.pl.

./perl-installed-modules-list.sh
--------------------------------

Provides a list of cpan installed modules. Depends on the "instmodsh" program.

Usage:
<pre>
./perl-installed-modules-list.sh
List of perl modules:
Available commands are:
   l            - List all installed modules
   m <module>   - Select a module
   q            - Quit the program
cmd? Installed modules are:
   CPAN
   Convert::ASN1
   Data::Dump
   IPC::Run3
   Mail::Sendmail
   Math::BigInt
   Net::LDAP
   Perl
</pre>



Installer script
----------------

You can install the utilities defined by `misc-tellSysAdmin` by:
* go to the `bin` directory
* a .env file (copy and modifu bin/.env.sample) and customise it to your requirements
* as a user with sudo capabilities, run ./local-deploy.sh [do]

Example:
<pre>`
../bin/local-deploy.sh
Deploying ap20-utils/misc-utils on smstest2
-- [MY] environment vars:
-- [MY] deployment vars:
MY_DEFAULT_PERMS=ubuntu:ubuntu
MY_EXCLUDED_HOSTS=([0]="xxxx")
MY_PERLLIB=/etc/perl
MY_USR_BIN=/usr/local/bin

-- copy ../src/rfindrep.pl /usr/local/bin []
   To be created with ubuntu:ubuntu 775

-- copy ../src/validateXML.pl /usr/local/bin []
   To be created with ubuntu:ubuntu 775

-- copy ../src/instmodsh /usr/local/bin []
   To be created with ubuntu:ubuntu 775

-- copy ../src/tellSysadmin.pl /usr/local/bin []
   To be created with ubuntu:ubuntu 775

-- copy ../src/perl-installed-modules-list.sh /usr/local/bin []
   To be created with ubuntu:ubuntu 775

-- copy ../src/myEmailer.pl /etc/perl []
   To be created with ubuntu:ubuntu 664
# eoj`
</pre>

If installed versions are different, this will be reported. Add "do" to execute the install.


