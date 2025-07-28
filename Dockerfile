FROM bitnami/minideb:latest

LABEL name="DockerPress for Coolify"
LABEL version="1.2.0"
LABEL release="2025-07-28"

WORKDIR /var/www/html

# Define PHP version
ARG PHP_VER=83

# ENV Defaults
ENV WP_CLI_CACHE_DIR "/var/www/.wp-cli/cache/"
ENV WP_CLI_PACKAGES_DIR "/var/www/.wp-cli/packages/"
ENV ADMIN_EMAIL "webmaster@host.com"
ENV ADMIN_PASS "dockerpress"
ENV ADMIN_USER "dockerpress"
ENV WP_LOCALE "en_US"
ENV WP_DEBUG false
ENV WORDPRESS_DB_PREFIX "wp_"
ENV WORDPRESS_DB_PORT 3306
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="1"
ENV DEBIAN_FRONTEND="noninteractive"
ENV DISABLE_WP_CRON=true

# HTTP port
EXPOSE "80/tcp"

# Webadmin port (HTTPS)
EXPOSE "7080/tcp"

# Install System Libraries
RUN apt-get update \
	&& \
	apt-get install -y --no-install-recommends \
	sudo \
	curl \
	cron \
	less \
	sysvbanner \
	wget \
	nano \
	htop \
	ghostscript \
	memcached \
  	libmemcached-dev \
  	libmemcached-tools \
	zip \
	unzip \
	git \
	memcached \
	libmemcached-tools \
	graphicsmagick \
	imagemagick \
	zlib1g \
	inetutils-ping \
	libxml2 \
	default-mysql-client\
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -rf /var/lib/apt/lists/* \
	&& sudo apt-get clean

# Make sure we have required tools
RUN install_packages \
	"curl" \
	"gnupg"

RUN wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | bash

# Install the Litespeed keys
RUN curl --silent --show-error \
	"http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg" |\
	apt-key add -

RUN curl --silent --show-error \
	"http://rpms.litespeedtech.com/debian/lst_repo.gpg" |\
	apt-key add -

# Install the Litespeed repository
# Detect the current Debian release
RUN . /etc/os-release && \
    echo "deb http://rpms.litespeedtech.com/debian/${VERSION_CODENAME} main" \
    > /etc/apt.sources.list.d/openlitespeed.conf

RUN apt-get update

# Install the Litespeed
RUN install_packages \
	"openlitespeed" && \
	echo "cloud-docker" > "/usr/local/lsws/PLAT"

# Install PageSpeed module
RUN install_packages \
	"ols-pagespeed"

# Install the PHP
RUN install_packages \
	"lsphp${PHP_VER}"

# Install PHP modules
RUN install_packages \
	"lsphp${PHP_VER}-apcu" \
	"lsphp${PHP_VER}-common" \
	"lsphp${PHP_VER}-curl" \
	"lsphp${PHP_VER}-igbinary" \
	"lsphp${PHP_VER}-imagick" \
	"lsphp${PHP_VER}-imap" \
	"lsphp${PHP_VER}-intl" \
	"lsphp${PHP_VER}-ldap" \
	"lsphp${PHP_VER}-memcached" \
	"lsphp${PHP_VER}-msgpack" \
	"lsphp${PHP_VER}-mysql" \
	"lsphp${PHP_VER}-opcache" \
	"lsphp${PHP_VER}-pear" \
	"lsphp${PHP_VER}-pgsql" \
	"lsphp${PHP_VER}-pspell" \
	"lsphp${PHP_VER}-redis" \
	"lsphp${PHP_VER}-sqlite3" \
	"lsphp${PHP_VER}-tidy"

# Set the default PHP CLI
RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp${PHP_VER}/bin/lsphp" \
	"/usr/local/lsws/fcgi-bin/lsphp5"

RUN ln --symbolic --force \
    "/usr/local/lsws/lsphp${PHP_VER}/bin/php${PHP_VER%.*}" \
    "/usr/bin/php"

# Install the certificates
RUN install_packages \
	"ca-certificates"

# Install requirements
RUN install_packages \
	"procps" \
	"tzdata"

# PHP Settings
RUN  sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /usr/local/lsws/lsphp${PHP_VER}/etc/php/${PHP_VER%.*}/litespeed/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 256M/g' /usr/local/lsws/lsphp${PHP_VER}/etc/php/${PHP_VER%.*}/litespeed/php.ini
RUN sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/lsws/lsphp${PHP_VER}/etc/php/${PHP_VER%.*}/litespeed/php.ini

COPY php/config/opcache.ini /usr/local/lsws/lsphp${PHP_VER}/etc/php/${PHP_VER%.*}/mods-available/opcache.ini

RUN touch /var/www/.opcache

COPY php/memcached.conf /etc/memcached.conf

# Create the directories
RUN mkdir --parents \
	"/tmp/lshttpd/gzcache" \
	"/tmp/lshttpd/pagespeed" \
	"/tmp/lshttpd/stats" \
	"/tmp/lshttpd/swap" \
	"/tmp/lshttpd/upload" \
	"/var/log/litespeed"

# Make sure logfiles exist
RUN touch \
	"/var/log/litespeed/server.log" \
	"/var/log/litespeed/access.log"

# Make sure we have access to files
RUN chown --recursive "lsadm:lsadm" \
	"/tmp/lshttpd" \
	"/var/log/litespeed"

# Configure the admin interface
COPY --chown="lsadm:lsadm" \
	"php/litespeed/admin_config.conf" \
	"/usr/local/lsws/admin/conf/admin_config.conf"

# Configure the server

# Template expansion: inject PHP version into config files
COPY php/litespeed/httpd_config.conf.template /tmp/httpd_config.conf.template
RUN envsubst '$PHP_VER' < /tmp/httpd_config.conf.template \
    > /usr/local/lsws/conf/httpd_config.conf

# Create the virtual host folders
RUN mkdir --parents \
	"/usr/local/lsws/conf/vhosts/wordpress" \
	"/var/www" \
	"/var/www/html" \
	"/var/www/tmp"

# Configure the virtual host
COPY --chown="lsadm:lsadm" \
	"php/litespeed/vhconf.conf" \
	"/usr/local/lsws/conf/vhosts/wordpress/vhconf.conf"

# Set up the virtual host configuration permissions
RUN chown --recursive "lsadm:lsadm" \
	"/usr/local/lsws/conf/vhosts/wordpress"

# Set up the virtual host document root permissions
RUN chown --recursive "www-data:www-data" \
	"/var/www/html"

RUN chown "www-data:www-data" \
	"/var/www"

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	; \
	rm -rf /var/lib/apt/lists/*

# Default Volume for Web
VOLUME /var/www/html

COPY wordpress/.htaccess /var/www

COPY wordpress/wp-config-sample.php /var/www/wp-config-sample.php

# Copy commands
COPY bin/* /usr/local/bin/

# Add Permissions
RUN chmod +x /usr/local/bin/wp
RUN chmod +x /usr/local/bin/mysql-optimize
RUN chmod +x /usr/local/bin/wpcli-run-clear-scheduler-log
RUN chmod +x /usr/local/bin/wpcli-run-clear-spams
RUN chmod +x /usr/local/bin/wpcli-run-delete-transient
RUN chmod +x /usr/local/bin/wpcli-run-media-regenerate
RUN chmod +x /usr/local/bin/wpcli-run-schedule

# Copy Crontab
COPY cron.d/dockerpress.crontab /etc/cron.d/dockerpress
RUN chmod 644 /etc/cron.d/dockerpress

RUN { \
	echo '[client]'; \
	echo 'user=MYUSER'; \
	echo "password='MYPASSWORD'"; \
	echo 'host=MYHOST'; \
	echo 'port=MYPORT'; \
	echo ''; \
	echo '[mysql]'; \
	echo 'database=MYDATABASE'; \
	echo ''; \
	} > /root/.my.cnf.sample

# Running wordpress startup scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default Port for Apache
EXPOSE 80

# Set the workdir and command
ENV PATH="/usr/local/lsws/bin:${PATH}"

ENTRYPOINT ["entrypoint.sh"]
