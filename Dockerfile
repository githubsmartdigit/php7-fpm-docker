FROM php:7-fpm-alpine
LABEL maintainer="Filipe <www@filipeandre.com>"
ARG TIMEZONE=Europe/Lisbon

RUN apk update && \
 apk upgrade && \
 apk add --no-cache bash git openssh-client dcron ca-certificates

# Install PHP extensions
ADD install-php /usr/sbin/install-php
RUN /usr/sbin/install-php
ENV PATH="/xooxx/.composer/vendor/bin:${PATH}"

#Npm
ENV NODE_VERSION 8.11.3
ENV YARN_VERSION 1.6.0
ADD install-npm /usr/sbin/install-npm
RUN /usr/sbin/install-npm

# Goofys
RUN apk add --no-cache --virtual=build-dependencies musl-dev go \
    && GOPATH=/tmp/go \
    && export GOPATH=$GOPATH \
    && go get github.com/kahing/goofys \
    && go install github.com/kahing/goofys \
    && cp $GOPATH/bin/goofys /usr/local/bin \
    \
    && apk add --no-cache fuse syslog-ng \
    \
    && echo '@version: 3.7' > /etc/syslog-ng/syslog-ng.conf \
    && echo 'source goofys {internal();network(transport("udp"));unix-dgram("/dev/log");};' >> /etc/syslog-ng/syslog-ng.conf \
    && echo 'destination goofys {file("/var/log/goofys");};' >> /etc/syslog-ng/syslog-ng.conf \
    && echo 'log {source(goofys);destination(goofys);};' >> /etc/syslog-ng/syslog-ng.conf \
    \
    && apk del build-dependencies \
    && rm -rf "/tmp/"*

# Cron
RUN mkdir -p /var/log/cron \
&& mkdir -m 0644 -p /var/spool/cron/crontabs \
&& touch /var/log/cron/cron.log \
&& mkdir -m 0644 -p /etc/cron.d
ADD cron-scheduler /usr/sbin/cron-scheduler

# Update CA
RUN mkdir -p /etc/ssl/certs && update-ca-certificates

# Set Timezone
RUN apk add --no-cache --update tzdata && \
    cp -v /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

# User and group
RUN addgroup -g 1000 xooxx \
 && adduser -D -u 1000 -G xooxx xooxx \
 && addgroup xooxx www-data

WORKDIR /code
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]