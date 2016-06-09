FROM debian:jessie

MAINTAINER Robin Thoni <robin@rthoni.com>

# Build php
# ======================================================================================================================

ENV PHPIZE_DEPS \
            autoconf \
            file \
            g++ \
            gcc \
            libc-dev \
            make \
            pkg-config \
            re2c
RUN apt-get update \
        && apt-get install -y \
		    $PHPIZE_DEPS \
		    ca-certificates \
		    curl \
		    libedit2 \
		    libsqlite3-0 \
		    libxml2 \
	        --no-install-recommends \
	    && rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /etc/php7.0
RUN mkdir -p $PHP_INI_DIR/conf.d

ENV PHP_EXTRA_CONFIGURE_ARGS --enable-maintainer-zts --enable-pthreads

ENV GPG_KEYS 1A4E8B7277C42E53DBA9C7B9BCAA30EA9C0D5763

ENV PHP_VERSION 7.0.7
ENV PHP_FILENAME php-7.0.7.tar.xz
ENV PHP_SHA256 9cc64a7459242c79c10e79d74feaf5bae3541f604966ceb600c3d2e8f5fe4794

RUN set -xe \
        && buildDeps=" \
            libcurl4-openssl-dev \
            libedit-dev \
            libsqlite3-dev \
            libssl-dev \
            libxml2-dev \
            xz-utils \
        " \
        && apt-get update \
        && apt-get install -y $buildDeps --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* \
        && curl -fSL "http://php.net/get/$PHP_FILENAME/from/this/mirror" -o "$PHP_FILENAME" \
        && echo "$PHP_SHA256 *$PHP_FILENAME" | sha256sum -c - \
        && curl -fSL "http://php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o "$PHP_FILENAME.asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && for key in $GPG_KEYS; do \
            gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
            done \
        && gpg --batch --verify "$PHP_FILENAME.asc" "$PHP_FILENAME" \
        && rm -r "$GNUPGHOME" "$PHP_FILENAME.asc" \
        && mkdir -p /usr/src/php \
        && tar -xf "$PHP_FILENAME" -C /usr/src/php --strip-components=1 \
        && rm "$PHP_FILENAME" \
        && cd /usr/src/php \
        && ./configure \
            --with-config-file-path="$PHP_INI_DIR" \
            --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
            $PHP_EXTRA_CONFIGURE_ARGS \
            --disable-cgi \
            --enable-mysqlnd \
            --enable-mbstring \
            --with-curl \
            --with-libedit \
            --with-openssl \
            --with-zlib \
        && make -j"$(nproc)" \
        && make install \
        && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
        && make clean \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps

RUN pecl install pthreads

# Install Composer
# ======================================================================================================================

RUN curl https://getcomposer.org/composer.phar -o /usr/local/bin/composer \
        && chmod +x /usr/local/bin/composer

RUN apt-get update \
        && apt-get install -y git unzip --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

# Add pdo and db drivers
# ======================================================================================================================

COPY docker-php-ext-* /usr/local/bin/

RUN buildDeps="libpq-dev libzip-dev " \
        && apt-get update \
        && apt-get install -y $buildDeps --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* \
        && docker-php-ext-install pdo pdo_pgsql pgsql

# Install PHP config file
# ======================================================================================================================

COPY php-cli.ini "${PHP_INI_DIR}"/

# Install sshd
# ======================================================================================================================

RUN apt-get update \
        && apt-get install -y openssh-server --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
RUN echo 'root:toor' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Run everything
# ======================================================================================================================

WORKDIR /data

VOLUME ["/data"]
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
