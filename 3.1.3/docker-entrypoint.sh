#!/bin/bash

# Change current directory to /kibana/src
cd /kibana/src

# Exit immediately if a command exits with a non-zero status
set -e

# Predefine the $url variable
url=""

if [ ! -z "$ELASTICSEARCH_PORT_9200_TCP_ADDR" ]; then
	# If the variable $ELASTCSIEARCH_PORT_9200_TCP_ADDR is set then
	url="http://$ELASTICSEARCH_PORT_9200_TCP_ADDR:9200"
elif [ ! -z "$ELASTICSEARCH_URL"]; then
	# If the variable $ELASTICSEARCH_URL is set then
	url=$ELASTICSEARCH_URL
fi

if [ ! -z "$url" ]; then
	# Replace http:// to https:\/\/ so we can consume it in sed
	string_to_replace='\/'
	ELASTICSEARCH_URL="${url//\//$string_to_replace}"

	sed -i 's/^\s*elasticsearch\:.*$/elasticsearch\:\"'$ELASTICSEARCH_URL'\",/' config.js

	# Set $1 to "gosu", $2 to "kibana", $3 to "python3 -m http.server 5601"
	set -- gosu kibana python3 -m http.server 5601
else
	# Output to stderr
	echo >&2 'warning: missing ELASTICSEARCH_PORT_9200_TCP or ELASTICSEARCH_URL'
	echo >&2 '  Did you forget to --link some-elasticsearch:elasticsearch'
	echo >&2 '  or -e ELASTICSEARCH_URL=http://some-elasticsearch:9200 ?'
	echo >&2

	exit 1;
fi

exec "$@"