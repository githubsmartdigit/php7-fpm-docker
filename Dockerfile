FROM php:7-fpm-alpine
LABEL maintainer="Filipe <www@filipeandre.com>"
ARG TIMEZONE=Europe/Lisbon
ENV PATH="/home/xooxx/.composer/vendor/bin:${PATH}"
ADD install-php /usr/sbin/install-php
ADD cron-scheduler /usr/sbin/cron-scheduler


RUN apk update && \
 apk upgrade && \
 apk add --no-cache bash git openssh-client dcron ca-certificates fuse syslog-ng tzdata && \
#Install nodejs
 apk add --no-cache --update --repository http://nl.alpinelinux.org/alpine/v3.8/main libuv=1.20.2-r0 npm nodejs && \
#Setup user
 addgroup -g 1000 xooxx && \
 adduser -D -s /bin/bash -u 1000 -G xooxx xooxx && \
 addgroup xooxx www-data && \
#Install php extensions
 /usr/sbin/install-php && \
#Install goofys
 apk add --no-cache --virtual=.build-deps musl-dev go && \
 GOPATH=/tmp/go && \
 export GOPATH=$GOPATH && \
 go get github.com/kahing/goofys && \
 go install github.com/kahing/goofys && \
 cp $GOPATH/bin/goofys /usr/local/bin && \
 echo '@version: 3.9' > /etc/syslog-ng/syslog-ng.conf && \
 echo 'source goofys {internal();network(transport("udp"));unix-dgram("/dev/log");};' >> /etc/syslog-ng/syslog-ng.conf && \
 echo 'destination goofys {file("/var/log/goofys");};' >> /etc/syslog-ng/syslog-ng.conf && \
 echo 'log {source(goofys);destination(goofys);};' >> /etc/syslog-ng/syslog-ng.conf && \
 chown xooxx:xooxx /etc/syslog-ng/syslog-ng.conf && \
 echo "user_allow_other" >> /etc/fuse.conf && \
#Install cron
 mkdir -p /var/log/cron && \
 mkdir -m 0644 -p /var/spool/cron/crontabs && \
 touch /var/log/cron/cron.log && \
 mkdir -m 0644 -p /etc/cron.d && \
#Update ca certificates
 mkdir -p /etc/ssl/certs && update-ca-certificates && \
#Set timezone
 cp -v /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
 echo "${TIMEZONE}" > /etc/timezone && \
#Cleanup
 apk del -f .build-deps && \
 rm -rf "/tmp/"*

WORKDIR /code
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]
