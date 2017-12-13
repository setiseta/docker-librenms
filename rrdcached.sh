#!/bin/bash
set -e

exec rrdcached -g -w 3600 -z 3600 -f 7200 -U librenms -G librenms -B -R -j /tmp -t 16 -F -b /data/rrd/ -l :42217