#!/bin/sh

TYPE=$1
PORT=$2
CONFIG="/var/run/redis/redis_${TYPE}.conf"

[ -z $TYPE ] && echo "missing type" && exit 1
[ -z $PORT ] && echo "missing port" && exit 1

sed -ie "s/%%PORT%%/${PORT}/g" $CONFIG
/redis/src/redis-server $CONFIG
