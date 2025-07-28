# DockerPress for Coolify

**DockerPress for Coolify** is a set of services that allows you to configure an exclusive Docker environment for WordPress with the most powerful tools like **OpenliteSpeed**, **Redis**, **Traefik** and **MySQL 8**.

DockerPress for Coolify has some Out of the Box features:

- [wp-cli (Wordpress Command Line Client)](https://wp-cli.org/)
- [OpenLiteSpeed](https://openlitespeed.org/)
- [OPcache](https://www.php.net/manual/pt_BR/book.opcache.php)
- [Automatically generation thumb images on background](https://br.wordpress.org/plugins/regenerate-thumbnails/)
- Automatically removes spam comments
- Automatically remove transient posts
- [Action Scheduler](https://actionscheduler.org/)

The official **DockerPress for Coolify** image can be accessed at [https://hub.docker.com/r/luizeof/dockerpress](https://hub.docker.com/r/luizeof/dockerpress).

## Environment Variables

Use the values below to configure your WordPress installation.

#### Database Settings

| ENV                   | Default | Required | Description         |
| --------------------- | ------- | -------- | ------------------- |
| WORDPRESS_DB_HOST     |         | Yes      | MySQL Host          |
| WORDPRESS_DB_PORT     | 3306    | Yes      | MySQL Port          |
| WORDPRESS_DB_NAME     |         | Yes      | MySQL Database Name |
| WORDPRESS_DB_PASSWORD |         | Yes      | MySQL Password      |
| WORDPRESS_DB_USER     |         | Yes      | MySQL Username      |

#### General Settings

| ENV          | Default        | Required | Description                                                                    |
| ------------ | -------        | -------- | ------------------------------------------------------------------------------ |
| COOLIFY_FQDN | Set in Coolify | Yes      | Website Domain                                                                 |
| ADMIN_USER   | DP4CAdmin      | Yes      | Wordpress Admin Username                                                         |
| ADMIN_EMAIL  |                | Yes      | Wordpress Admin E-mail                                                         |
| WP_LOCALE    | en_US          | No       | Wordpress Locale ([Available Locales](https://translate.wordpress.org/stats/)) |
| WP_DEBUG     | false          | No       | Enable / Disable Wordpress Debug                                               |

## Container Volume

By default, DockerPress for Coolify uses a single volume that must be mapped to `/var/www/html`. The entire WordPress installation is stored in this path.
