ap20-utils/basex
================

These BaseX utility script allow multiple instances of basex, with different sets of databases, to share a single BaseX installation.

Suggested setup of BaseX distro inside an admin dir
---------------------------------------------------

There is no automated installer; install manually as described below.

For example, assuming your standard Basex distro has been setup like this:
<pre>
mkdir /srv/base
cd /srv/base
mkdir logs bin scripts webwork
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

