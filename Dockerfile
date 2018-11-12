FROM php:7-fpm-alpine
LABEL maintainer="Filipe <www@filipeandre.com>"
ARG TIMEZONE=Europe/Lisbon
ENV PATH="/home/xooxx/.composer/vendor/bin:${PATH}"
ADD install-php /usr/sbin/install-php
ADD cron-scheduler /usr/sbin/cron-scheduler
ENV VERSION=v10.13.0 NPM_VERSION=6 YARN_VERSION=latest
ENV CONFIG_FLAGS="--fully-static --without-npm" DEL_PKGS="libstdc++" RM_DIRS=/usr/include

RUN apk update && \
 apk upgrade && \
 apk add --no-cache bash git openssh-client dcron ca-certificates fuse syslog-ng tzdata && \
 apk add --no-cache --virtual=.node-deps curl make gcc g++ python linux-headers binutils-gold gnupg libstdc++ &&\
#Install nodejs
   for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
    gpg --keyserver $server --recv-keys \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      77984A986EBC2AA786BC0F66B01FBB92821C587A \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D && break; \
  done && \
  curl -sfSLO https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.xz && \
  curl -sfSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc | gpg --batch --decrypt | \
    grep " node-${VERSION}.tar.xz\$" | sha256sum -c | grep ': OK$' && \
  tar -xf node-${VERSION}.tar.xz && \
  cd node-${VERSION} && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  make -j$(getconf _NPROCESSORS_ONLN) && \
  make install && \
  cd / && \
  if [ -z "$CONFIG_FLAGS" ]; then \
    if [ -n "$NPM_VERSION" ]; then \
      npm install -g npm@${NPM_VERSION}; \
    fi; \
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
    if [ -n "$YARN_VERSION" ]; then \
      for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
        gpg --keyserver $server --recv-keys \
          6A010C5166006599AA17F08146C2130DFD2497F5 && break; \
      done && \
      curl -sfSL -O https://yarnpkg.com/${YARN_VERSION}.tar.gz -O https://yarnpkg.com/${YARN_VERSION}.tar.gz.asc && \
      gpg --batch --verify ${YARN_VERSION}.tar.gz.asc ${YARN_VERSION}.tar.gz && \
      mkdir /usr/local/share/yarn && \
      tar -xf ${YARN_VERSION}.tar.gz -C /usr/local/share/yarn --strip 1 && \
      ln -s /usr/local/share/yarn/bin/yarn /usr/local/bin/ && \
      ln -s /usr/local/share/yarn/bin/yarnpkg /usr/local/bin/ && \
      rm ${YARN_VERSION}.tar.gz*; \
    fi; \
  fi && \
#Setup user
 addgroup -g 1000 xooxx && \
 adduser -D -s /bin/bash -u 1000 -G xooxx xooxx && \
 addgroup xooxx www-data && \
#Install php extensions
 /usr/sbin/install-php && \
#Install goofys
 apk add --no-cache --virtual=.go musl-dev go-deps && \
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
 apk del -f .node-deps
 apk del -f .go-deps && \
 rm -rf "/tmp/"*

WORKDIR /code
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm"]
