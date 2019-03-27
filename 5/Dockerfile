FROM debian:stretch-slim

RUN apt-get update && apt-get install -y \
		apt-transport-https \
		ca-certificates \
		gnupg2 dirmngr \
		wget \
# generating PDFs requires libfontconfig and libfreetype6
		libfontconfig \
		libfreetype6 \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.11
# grab tini for signal processing and zombie killing
ENV TINI_VERSION v0.18.0
RUN set -eux; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	\
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
	wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-$dpkgArch"; \
	wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-$dpkgArch.asc"; \
	\
# verify the signatures
# (for flaky keyservers, consider https://github.com/tianon/pgp-happy-eyeballs, ala https://github.com/docker-library/php/pull/666)
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5; \
	gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc; \
	\
	chmod +x /usr/local/bin/gosu /usr/local/bin/tini; \
# verify that the binaries work
	gosu --version; \
	gosu nobody true; \
	tini --version; \
	tini true

RUN set -ex; \
# https://artifacts.elastic.co/GPG-KEY-elasticsearch
	key='46095ACC8548582C1A2699A9D27D666CD88E42B4'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/elastic.gpg; \
	rm -rf "$GNUPGHOME"; \
	apt-key list

RUN groupadd -r -g 999 kibana && useradd -r -m -g kibana -u 999 kibana

# https://www.elastic.co/guide/en/kibana/5.0/deb.html
RUN echo 'deb https://artifacts.elastic.co/packages/5.x/apt stable main' > /etc/apt/sources.list.d/kibana.list

ENV KIBANA_VERSION 5.6.16

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends kibana=$KIBANA_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	\
# the default "server.host" is "localhost" in 5+
	&& sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" /etc/kibana/kibana.yml \
	&& grep -q "^server\.host: '0.0.0.0'\$" /etc/kibana/kibana.yml \
	\
# ensure the default configuration is useful when using --link
	&& sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 'http://elasticsearch:9200'!" /etc/kibana/kibana.yml \
	&& grep -q "^elasticsearch\.url: 'http://elasticsearch:9200'\$" /etc/kibana/kibana.yml

ENV PATH /usr/share/kibana/bin:$PATH

COPY docker-entrypoint.sh /

EXPOSE 5601
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kibana"]
