#!/bin/bash
set -e

# Add kibana as command if needed
if [[ "$1" == -* ]]; then
	set -- kibana "$@"
fi

# Run as user "kibana" if the command is "kibana"
if [ "$1" = 'kibana' ]; then
	if [ "$ELASTICSEARCH_URL" ]; then
		sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 '$ELASTICSEARCH_URL'!" /opt/kibana/config/kibana.yml
	fi

  [ ! -z "$ELASTICSEARCH_USERNAME" ] && sed -ri "s%^(\#\s*)?(elasticsearch\.username:).*%\2 '$ELASTICSEARCH_USERNAME'%" /opt/kibana/config/kibana.yml
  [ ! -z "$ELASTICSEARCH_PASSWORD" ] && sed -ri "s%^(\#\s*)?(elasticsearch\.password:).*%\2 '$ELASTICSEARCH_PASSWORD'%" /opt/kibana/config/kibana.yml
  
	set -- gosu kibana tini -- "$@"
fi

exec "$@"
