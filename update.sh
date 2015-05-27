#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versionPage="https://www.elastic.co$(curl -fsSL 'https://www.elastic.co/downloads/past-releases' |tac|tac | grep -m1 '"/downloads/past-releases/kibana-' | awk -F '[<>="]+' '{ print $4 }')"
fullVersion="$(curl -fsSL "$versionPage" | grep -Em1 '<a href="https://download.elastic.co/kibana/kibana/kibana-[^"]+-linux-x64.tar.gz"' | sed -r 's!^.*"https://download.elastic.co/kibana/kibana/kibana-|-linux-x64.tar.gz".*$!!g')"
sha1="$(curl -fsSL "https://download.elastic.co/kibana/kibana/kibana-$fullVersion-linux-x64.tar.gz.sha1.txt" | cut -d' ' -f1)"

set -x
sed -ri '
	s/^(ENV KIBANA_VERSION) .*/\1 '"$fullVersion"'/;
	s/^(ENV KIBANA_SHA1) .*/\1 '"$sha1"'/;
' Dockerfile
