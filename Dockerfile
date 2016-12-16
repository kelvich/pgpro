# based on official docker image for postgres on alpine
FROM alpine:3.4

ENV LANG en_US.utf8

RUN mkdir /docker-entrypoint-initdb.d

ENV PG_MAJOR 9.6
ENV PGPRO_VERSION 9.6.1.2
ENV PG_SHA256 6911ba75a5dff747d8edd7d501c97dcb1d3c2a41733998f1b2332d37f9879bd0

RUN set -ex \
	\
	&& apk add --no-cache --virtual .fetch-deps \
		ca-certificates \
		openssl \
		tar \
	\
	&& wget -O postgresql.tar.bz2 "http://repo.postgrespro.ru/pgpro-$PG_MAJOR/src/postgrespro-$PGPRO_VERSION.tar.bz2" \
	&& echo "$PG_SHA256 *postgresql.tar.bz2" | sha256sum -c - \
	&& mkdir -p /usr/src/postgresql \
	&& tar \
		--extract \
		--file postgresql.tar.bz2 \
		--directory /usr/src/postgresql \
		--strip-components 1 \
	&& rm postgresql.tar.bz2 \
	\
	&& apk add --no-cache --virtual .build-deps \
		bison \
		flex \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		perl \
		zlib-dev \
		readline-dev \
	\
	&& cd /usr/src/postgresql \
	\
	&& ./configure \
		--with-system-tzdata=/usr/share/zoneinfo \
		--prefix=/usr/local \
		--with-openssl \
	\
	&& make -j "$(getconf _NPROCESSORS_ONLN)" world \
	&& make install \
	&& make -C contrib install \
	\
	&& mkdir contrib/rum \
	&& wget -O rum.tar.gz "https://github.com/postgrespro/rum/archive/0.1.tar.gz" \
	&& tar xzf rum.tar.gz -C contrib/rum --strip-components=1 \
	&& cd contrib/rum \
	&& USE_PGXS=1 make -j "$(getconf _NPROCESSORS_ONLN)" install \
	\
	&& apk del .fetch-deps .build-deps \
	&& rm -rf /usr/src/postgresql

RUN apk add --no-cache --virtual .postgresql-rundeps \
		su-exec \
		tzdata \
		bash

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]