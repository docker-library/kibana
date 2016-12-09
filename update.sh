#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

tags="$(git ls-remote --tags https://github.com/elastic/kibana.git | cut -d/ -f3 | cut -d^ -f1 | cut -dv -f2 | sort -rV)"
debArch="$(dpkg --print-architecture)"

travisEnv=
for version in "${versions[@]}"; do
	# major.minor.patch
	versionMajor="${version%%.*}"
	versionMinor="${version#$versionMajor.}"
	[ "$versionMinor" != "$version" ] || versionMinor=
	versionMinor="${versionMinor%%.*}"

	fullVersion=
	sha1=
	if (
		[ "$versionMajor" -eq 4 ] \
		&& [ -n "$versionMinor" ] \
		&& [ "$versionMinor" -ge 4 ] \
	) || [ "$versionMajor" -gt 4 ]; then
		if [ "$versionMajor" -eq 5 ]; then
			repoBase='https://artifacts.elastic.co/packages/5.x/apt'
		else
			repoBase="http://packages.elastic.co/kibana/$version/debian"
		fi
		packagesUri="$repoBase/dists/stable/main/binary-$debArch/Packages"
		debVersions="$(
			curl -fsSL "$packagesUri" \
				| awk -F ': +' '
					$1 == "Package" { pkg = $2 }
					pkg == "kibana" && $1 == "Version" { print $2 }
				' \
				| sort -rV
		)"
		fullVersion="$(echo "$debVersions" | head -n1)"
	else
		possibleVersions="$(echo "$tags" | grep "^$version\.")"
		nonBetaVersions="$(echo "$possibleVersions" | grep -vE 'milestone|-beta|-m')"
		# prefer full releases over beta or milestone
		if [ "$nonBetaVersions" ]; then
			fullVersion="$(echo "$nonBetaVersions" | head -n1)"
		else
			fullVersion="$(echo "$possibleVersions" | head -n1)"
		fi

		sha1="$(curl -fsSL "https://download.elastic.co/kibana/kibana/kibana-$fullVersion-linux-x64.tar.gz.sha1.txt" | cut -d' ' -f1)"
	fi

	if [ -z "$fullVersion" ]; then
		echo >&2
		echo >&2 "warning: unable to figure out 'full version' for $version"
		echo >&2 '    skipping'
		echo >&2
		continue
	fi

	(
		set -x
		sed -ri '
			s/^(ENV KIBANA_MAJOR) .*/\1 '"$version"'/;
			s/^(ENV KIBANA_VERSION) .*/\1 '"$fullVersion"'/;
			s/^(ENV KIBANA_SHA1) .*/\1 '"$sha1"'/;
		' "$version/Dockerfile"
	)

	travisEnv='\n  - VERSION='"$version$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
