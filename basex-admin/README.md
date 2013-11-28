ap20-utils/basex
================

These BaseX utility script allow multiple instances of basex, with different sets of databases, to share a single BaseX installation.

Automated installation
----------------------
Using a userid with sudo rights, cd basex-admin/bin and run ./local-deploy.sh and follow its instructions. You'll be advised as to what environment variables need to be set for the operational scripts. The variables you define by copying .env.sample to .env are only used in the installation/deployment script.

When satisfied with your environment settings, run: 
<pre>
   ./local-deploy.sh do
</pre>

To check your environment settings, run:
<pre>
   ./local-deploy.sh check
</pre>

You can run `./local-deploy.sh` at any time and it will report any variances. This means you can feel free to ypdate the ap20-utils repository from github at any time without it affecting your operational deployment in any way.

Suggested setup of BaseX distro inside an admin dir
---------------------------------------------------

There is automated installer; install manually as described below.

For example, assuming your standard Basex distro has been setup like this:
<pre>
mkdir /srv/basex
cd /srv/basex
mkdir logs bin scripts webwork # note: the webwork dir should be writable by the `BASEX_USER`
wget http://files.basex.org/releases/7.7.2/BaseX772.zip
unzip BaseX772.zip

We now have for BASEX:
      ADMIN:       /srv/basex           # basex administration directory
      MYLOGS:      /srv/basex/logs      # log files placeholder
      MYBIN:       /srv/basex/bin       # utility scripts
      MYSCRIPTS:   /srv/basex/scripts   # for reusable basex scripts
      WEBWORK:     /srv/basex/webwork   # work area for basex restxq/web apps
      BASEXHOME:   /srv/basex/basex (BaseX normal installation)
</pre>

Note: I prefer to keep basex databases separate from the basex distribution. See the `BASEX_DATABASE` environment variable.

Enhanced stop/start scripts for multiple instances
--------------------------------------------------

The additional scripts supplied in this repo (ap20-utils/basex) are:

<pre>
src/etc.init.d/basex          : a start/stop controller
                                ( install in /etc/init.d/basex as root )

src/usr.local.sbin/basex.sh   : basex start/stop, called from /etc/init.d/basex
                                ( install in /usr/local/sbin/basex.sh as root )

                               Modify as required for:
                                  BASEX_USER='fas'
                                  BASEX_HOME="/srv/basex/basex"
                                  BASEX_DATABASES="/data/bx/db"
                                  BASEX_MYSETTINGSDIR="/srv/basex/.mysettings"
         
src/basex-admin/basex/bin/mybasexhttp     : an adapted version of basex/bin/basexhttp[stop] scripts
src/basex-admin/basex/bin/mybasexhttpstop   ( install these 2 in BASEX $HOME/bin )
</pre>

Copy the .mysettings dir to $ADMIN. Modify the file there to suit:
<pre>
    BX_DBPATH : the location for basex database
    BX_JVMSIZE: java preferences 
</pre>

This allows multiple instances of basex, with different sets of databases, to share a single BaseX installation.

It works by soft mapping the basename of the /usr/local/sbin script to a file in $ADMIN/.mysettings. E.G.:
<pre>
    /usr/local/sbin/basex.sh    will cause /srv/basex/.mysettings/basex    to be used
    /usr/local/sbin/basexdev.sh will cause /srv/basex/.mysettings/basexdev to be used
</pre>


src/basex-admin/bin
-------------------

Various scripts to assist with automated database creation.

src/basex-admin/webwork/schemas
-------------------------------

Contains local copies of xml schemas for TEI and EAC\_CPF. Add others as required. 

