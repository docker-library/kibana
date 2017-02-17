#!/bin/bash
set -e

# Add kibana as command if needed
if [[ "$1" == -* ]]; then
	set -- kibana "$@"
fi

# Run as user "kibana" if the command is "kibana"
if [ "$1" = 'kibana' ]; then
	if [ "$ELASTICSEARCH_URL" ]; then
		sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 '$ELASTICSEARCH_URL'!" /etc/kibana/kibana.yml
	fi
        if [ "$ELASTICSEARCH_USERNAME" ]; then
                sed -ri "s!^(\#\s*)?(elasticsearch\.username:).*!\2 '$ELASTICSEARCH_USERNAME'!" /etc/kibana/kibana.yml
        fi
        if [ "$ELASTICSEARCH_PASSWORD" ]; then
                sed -ri "s!^(\#\s*)?(elasticsearch\.password:).*!\2 '$ELASTICSEARCH_PASSWORD'!" /etc/kibana/kibana.yml
        fi

	set -- gosu kibana tini -- "$@"
fi

exec "$@"
