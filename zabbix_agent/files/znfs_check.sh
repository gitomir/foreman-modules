#!/bin/bash
if [ "$1" == "" ]; then
  echo "Usage: $0 <mount-point>"
  exit 0;
fi

mountpoint="$1"

read -t1 < <(stat -t "$mountpoint" 2>&-)
if [[ -n "$REPLY" ]]; then
  echo "1"
else
  echo "0"
fi
