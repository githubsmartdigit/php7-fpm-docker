FROM php:7-fpm-alpine
LABEL maintainer="Filipe <www@filipeandre.com>"
ARG TIMEZONE=Europe/Lisbon

RUN apk update && apk upgrade --no-cache && \
	apk add --no-cache bash git openssh-client ca-certificates fuse syslog-ng tzdata sudo && \
	mkdir -p /etc/ssl/certs && update-ca-certificates && \
 	cp -v /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
 	echo "${TIMEZONE}" > /etc/timezone && \
	addgroup -g 1000 xooxx && \
	adduser -D -s /bin/bash -u 1000 -G xooxx xooxx && \
	addgroup xooxx www-data && \
	rm -rf "/tmp/"*

ADD install-php /usr/sbin/install-php
RUN	chmod 775 /usr/sbin/install-php && \
	/usr/sbin/install-php && \
	rm -rf "/tmp/"*
	
ADD install-goofys /usr/sbin/install-goofys
RUN	chmod 775 /usr/sbin/install-goofys && \
	/usr/sbin/install-goofys && \
	rm -rf "/tmp/"*

RUN apk add -u python py-pip && \
	pip install supervisor && \
	rm -rf "/tmp/"*

ADD install-node /usr/sbin/install-node
RUN	chmod 775 /usr/sbin/install-node && \
	/usr/sbin/install-node && \
	rm -rf "/tmp/"*

ENV PATH="/home/xooxx/.local/bin:/home/xooxx/.composer/vendor/bin:${PATH}"

WORKDIR /code
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]
