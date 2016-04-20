#!/bin/bash
#
# Name: zmemcache
#
# Checks Memcached stats using netcat

KEY=$1

cmd=$(echo -e "stats\\nquit" | nc 127.0.0.1 11211 | grep "STAT $KEY " | awk '{print $3}')
#val=$(echo $cmd | awk '/STAT $KEY /{print $$3}')

echo $cmd

