FROM debian:jessie

ENV REFRESHED_AT 20150813

# add our user and group first to make sure their IDs get assigned consistently
RUN groupadd -r kibana && useradd -r -g kibana kibana

RUN apt-get update &&\
    apt-get install -y python3 ca-certificates curl --no-install-recommends &&\
    rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN arch="$(dpkg --print-architecture)" \
  && set -x \
  && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch" \
  && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch.asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

ENV KIBANA_VERSION 3.1.2
# Generate KIBANA_SHA1 with: sha1sum ~/Downloads/kibana-3.1.2.tar.gz
ENV KIBANA_SHA1 a59ea4abb018a7ed22b3bc1c3bcc6944b7009dc4

RUN set -x \
  && curl -fSL "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_VERSION}.tar.gz" -o kibana.tar.gz \
  && echo "${KIBANA_SHA1}  kibana.tar.gz" | sha1sum -c - \
  && tar -xzvf kibana.tar.gz \
  && rm kibana.tar.gz \
  && mv kibana-$KIBANA_VERSION kibana

WORKDIR /kibana/src

COPY ./docker-entrypoint.sh /

EXPOSE 5601
ENTRYPOINT ["/docker-entrypoint.sh"]
