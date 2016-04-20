#!/bin/bash
KEY=$1
cmd=$(mysql -uuser1 -pcrim73 -h $KEY -e "")
echo $?
