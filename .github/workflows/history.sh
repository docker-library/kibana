#!/usr/bin/env bash
set -Eeuo pipefail

# "docker history", but ignoring/munging known problematic bits for the purposes of creating image diffs

docker image history --no-trunc --format '{{ .CreatedBy }}' "$@" \
	| tac \
	| sed -r 's!^/bin/sh[[:space:]]+-c[[:space:]]+(#[(]nop[)][[:space:]]+)?!!' \
	| gawk '
		# munge the checksum of the first ADD of the base image (base image changes unnecessarily break our diffs)
		NR == 1 && $1 == "ADD" && $4 == "/" { $2 = "-" }

		# just ignore the default CentOS CMD value (not relevant to our needs)
		$0 == "CMD [\"/bin/bash\"]" { next }

		# ignore the contents of certain copies (notoriously unreliable hashes because they often contain timestamps)
		$1 == "COPY" && $4 == "/usr/share/kibana/config/kibana.yml" { gsub(/:[0-9a-f]{64}$/, ":filtered-content-hash", $2) }

		# remove "org.label-schema.build-date" and "org.opencontainers.image.created" (https://github.com/elastic/dockerfiles/pull/101#pullrequestreview-879623350)
		$1 == "LABEL" { gsub(/ (org[.]label-schema[.]build-date|org[.]opencontainers[.]image[.]created)=[^ ]+( [0-9:+-]+)?/, "") }

		# sane and sanitized, print it!
		{ print }
	'
