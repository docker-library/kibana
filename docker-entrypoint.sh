#!/bin/bash

set -e

# Add kibana as command if needed
if [[ "$1" == -* ]]; then
	set -- kibana "$@"
fi

# Run as user "kibana" if the command is "kibana"
if [ "$1" = 'kibana' ]; then
	if [ "$ELASTICSEARCH_URL" ]; then
		sed -ri "s!^(elasticsearch_url:).*!\1 '$ELASTICSEARCH_URL'!" /opt/kibana/config/kibana.yml
	elif [ "$ELASTICSEARCH_PORT_9200_TCP" ]; then
		sed -ri 's!^(elasticsearch_url:).*!\1 "http://elasticsearch:9200"!' /opt/kibana/config/kibana.yml
	else
		echo >&2 'warning: missing ELASTICSEARCH_PORT_9200_TCP or $ELASTICSEARCH_URL'
		echo >&2 '  Did you forget to --link some-elasticsearch:elasticsearch or set the environnement variable?'
		echo >&2
	fi
	
	set -- gosu kibana "$@"
fi

exec "$@"
