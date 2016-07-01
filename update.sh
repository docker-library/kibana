#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	echo "Usage: bash update.sh [version ...]"
	exit 1
fi
versions=( "${versions[@]%/}" )

function writeFiles {
	local fullVersion=$1
	local variant=$2

	shortVersion=$(echo $fullVersion | sed -r -e 's/^([0-9]+.[0-9]+).*/\1/')
	if [[ -z $variant ]]; then
		targetDir="$shortVersion"
		template=Dockerfile.template
	else
		targetDir="$shortVersion/$variant"
		template=Dockerfile-$variant.template
	fi

	mkdir -p "$targetDir"
	cp $template "$targetDir/Dockerfile"
	if [[ -f docker-entrypoint.sh ]]; then
		cp -r docker-entrypoint.sh "$targetDir"
	fi

	if [[ $variant == 'alpine' ]]; then
		sed -r -i -e 's/(gosu)/'"su-exec"'/' "$targetDir/docker-entrypoint.sh"
	fi

	sha1="$(curl -fsSL "https://download.elastic.co/kibana/kibana/kibana-$fullVersion-linux-x64.tar.gz.sha1.txt" | cut -d' ' -f1)"
	sed -r -i -e 's/^(ENV KIBANA_MAJOR) .*/\1 '"$shortVersion"'/' "$targetDir/Dockerfile"
	sed -r -i -e 's/^(ENV KIBANA_VERSION) .*/\1 '"$fullVersion"'/' "$targetDir/Dockerfile"
	sed -r -i -e 's/^(ENV KIBANA_SHA1) .*/\1 '"$sha1"'/' "$targetDir/Dockerfile"
}

tags="$(git ls-remote --tags https://github.com/elastic/kibana.git | cut -d/ -f3 | cut -d^ -f1 | cut -dv -f2 | sort -rV)"

travisEnv=
for version in "${versions[@]}"; do
	possibleVersions="$(echo "$tags" | grep "^$version." )"
	# prefer full releases over beta or milestone
	if releaseVersions="$(echo "$possibleVersions" | grep -vEm1 'milestone|-alpha|-beta|-m')"; then
		fullVersion="$releaseVersions"
	else
		fullVersion="$(echo "$possibleVersions" | head -n1)"
	fi

	if [[ -z $fullVersion ]]; then
		echo "Cannot find version: $version"
		exit 1
	fi

	(
		set -x
		writeFiles $fullVersion
		writeFiles $fullVersion 'alpine'
	)

	travisEnv='\n  - VERSION='"$version VARIANT=alpine$travisEnv"
	travisEnv='\n  - VERSION='"$version$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
