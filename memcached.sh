#!/bin/bash
set -e

exec memcached -v -m 64 -p 11211 -u memcache -l 0.0.0.0
