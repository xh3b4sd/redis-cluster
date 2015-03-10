#!/bin/sh

PORT=$1
CONFIG="/var/run/redis/redis.conf"

[ "$PORT" = "" ] && echo "missing port" && exit 1

sed -ie "s/%%PORT%%/${PORT}/g" $CONFIG
/redis/src/redis-server $CONFIG
