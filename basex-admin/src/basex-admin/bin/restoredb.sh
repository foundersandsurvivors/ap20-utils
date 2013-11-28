#!/bin/bash
cd $BASEX_DISTRO
bin/basexclient -c "restore $1"
exit $?
