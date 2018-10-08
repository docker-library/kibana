#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

tags="$(git ls-remote --tags https://github.com/elastic/kibana.git | cut -d/ -f3 | cut -d^ -f1 | cut -dv -f2 | sort -rV)"
debArch="$(dpkg --print-architecture)"

travisEnv=
for version in "${versions[@]}"; do
	rcVersion="${version%-rc}"

	majorVersion="${rcVersion%%.*}"
	aptBucket="${majorVersion}.x"
	if [ "$rcVersion" != "$version" ]; then
		aptBucket+='-prerelease'
	fi
	debRepo="https://artifacts.elastic.co/packages/$aptBucket/apt"
	tarballUrlBase='https://artifacts.elastic.co/downloads'
	if [ "$majorVersion" -eq 2 ]; then
		debRepo="http://packages.kibana.org/kibana/$aptBucket/debian"
		tarballUrlBase='https://download.elastic.co/kibana'
	fi

	fullVersion="$(curl -fsSL "$debRepo/dists/stable/main/binary-amd64/Packages" | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "kibana" && $1 == "Version" && $2 ~ /^([0-9]+:)?'"$rcVersion"'/ { print $2 }' | sort -rV | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	# convert "1:5.0.2-1" over to "5.0.2"
	plainVersion="${fullVersion%%-*}" # strip non-upstream-version
	plainVersion="${plainVersion##*:}" # strip epoch
	tilde='~'; plainVersion="${plainVersion//$tilde/-}" # replace '~' with '-'

	if [ $majorVersion -ge 6 ]; then
		# Use the "upstream" Dockerfile, which rebundles the existing image from Elastic.
		upstreamImage="docker.elastic.co/kibana/kibana:$plainVersion"
		
		# Parse image manifest for sha
		authToken="$(curl -fsSL 'https://docker-auth.elastic.co/auth?service=token-service&scope=repository:kibana/kibana:pull' | jq -r .token)"
		digest="$(curl --head -fsSL -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -H "Authorization: Bearer $authToken" "https://docker.elastic.co/v2/kibana/kibana/manifests/$plainVersion" | tr -d '\r' | gawk -F ':[[:space:]]+' '$1 == "Docker-Content-Digest" { print $2 }')"

		# Format image reference (image@sha)
		upstreamImageDigest="$upstreamImage@$digest"

		(
			set -x
			sed '
				s!%%KIBANA_VERSION%%!'"$plainVersion"'!g;
				s!%%UPSTREAM_IMAGE_DIGEST%%!'"$upstreamImageDigest"'!g;
			' Dockerfile-upstream.template > "$version/Dockerfile"
		)
		travisEnv='\n  - VERSION='"$version$travisEnv"
	else
		repoBase='https://artifacts.elastic.co/packages/5.x/apt'

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
			' "$version/Dockerfile"
		)

		travisEnv='\n  - VERSION='"$version$travisEnv"
	fi
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
