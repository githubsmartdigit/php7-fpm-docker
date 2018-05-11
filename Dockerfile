FROM php:7-fpm-alpine
LABEL maintainer="Filipe <www@filipeandre.com>"

RUN apk update && \
 apk upgrade && \
 apk add --no-cache bash git

# Install PHP extensions
ADD install-php /usr/sbin/install-php
RUN /usr/sbin/install-php

RUN mkdir -p /etc/ssl/certs && update-ca-certificates

# Set Timezone
ARG TIMEZONE=Europe/Lisbon
RUN apk add --no-cache --update tzdata && \
    cp -v /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

WORKDIR /code
