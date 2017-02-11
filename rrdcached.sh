#!/bin/bash
set -e

exec rrdcached -g -w 3600 -z 3600 -f 7200 -s librenms -U librenms -G librenms -B -R -j /var/tmp -l unix:/var/run/rrdcached/rrdcached.sock -t 16 -F -b /data/rrd/
