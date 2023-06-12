#!/bin/bash

set -x

if [ ${#@} -lt 1 ];
then
echo "usage: $0 [your github token] [REST expression]"
exit 1;
fi

#GITHUB_TOKEN="xxxxxxxxxxxxxxxxxx"
TOKEN_API=$(echo "$token")
echo "This is the token from command line: $TOKEN_API"
GITHUB_PATH=$1
echo "username: $GITHUB_USERNAME"
#GITHUB_API_ENDPOINT=$2

GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github+json"

temp=`basename $0`
TMPFILE=`mktemp /tmp/${temp}.XXXXXX` || exit 1

function rest_call {
  curl -L "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: Bearer $TOKEN_API"
}


#last_page=`curl -L "https://api.github.com${GITHUB_PATH}" -H "${GITHUB_API_HEADER_ACCEPT}" \
#-H "Authorization: Bearer $TOKEN_API" | grep '^Link:' | sed -e 's/^Link:.*page=//g' -e 's/>.*$//g'`

#last_page=`curl -L "https://api.github.com${GITHUB_PATH}" -H "${GITHUB_API_HEADER_ACCEPT}" \
#-H "Authorization: Bearer $TOKEN_API" | grep -w 'html_url' | grep -io 'https://github.com/jimihunter2002/[a-zA-Z0-9.+-]*'`

last_page=`curl -L "https://api.github.com${GITHUB_PATH}" -H "${GITHUB_API_HEADER_ACCEPT}" \
-H "Authorization: Bearer $TOKEN_API" | jq '.[] | .html_url'`

echo "$last_page" >> $TMPFILE

#take care of pagination?

#if [ -z "last_page" ]; then
   #rest_call "https://api.github.com${GITHUB_PATH}"
#else
# yes - this result is on multiple pages

#for p in `seq 1 $last_page`; do
  #rest_call "https://api.github.com${GITHUB_PATH}?page=$p"
#done
#fi

cat $TMPFILE
