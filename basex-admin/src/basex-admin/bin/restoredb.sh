#!/bin/bash
cd /srv/basex/basex
bin/basexclient -c "restore $1"
exit $?
