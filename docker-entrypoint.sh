#!/bin/bash

set -e

# Add kibana as command if needed
if [[ "$1" == -* ]]; then
	set -- kibana "$@"
fi

# Run as user "kibana" if the command is "kibana"
if [ "$1" = 'kibana' ]; then
	if [ "$ELASTICSEARCH_PORT_9200_TCP" ]; then
		sed -ri 's!^(elasticsearch_url:).*!\1 "http://elasticsearch:9200"!' /opt/kibana/config/kibana.yml
	else
		echo >&2 'warning: missing ELASTICSEARCH_PORT_9200_TCP'
		echo >&2 '  Did you forget to --link some-elasticsearch:elasticsearch ?'
		echo >&2
	fi
	
	set -- gosu kibana "$@"
fi

exec "$@"
