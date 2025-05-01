#!/bin/bash

apt-get update

## Variables ##
DATABASE_NAME="wordpress_db"
DATABASE_PASSWORD="Passw0rd!"

NGINX_SERVER_NAME="localhost"

## MARIADB ##
apt-get -y install mariadb-server

mysql -u root -e "CREATE DATABASE $DATABASE_NAME;"
mysql -u root -e "GRANT ALL ON $DATABASE_NAME.* TO 'wpuser'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

## PHP ##
apt-get -y install --no-install-recommends \
  php8.3 \
  php8.3-cli \
  php8.3-fpm \
  php8.3-mysql \
  php8.3-json \
  php8.3-opcache \
  php8.3-mbstring \
  php8.3-xml \
  php8.3-gd \
  php8.3-curl

mkdir -p /var/www/html/wordpress/public_html

## Wordpress ##
wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
tar -zxvf /tmp/wordpress.tar.gz -C /var/www/html/
rm -f /tmp/wordpress.tar.gz

chown -R www-data:www-data /var/www/html/wordpress
#chmod -R 755 *
rm wp-config-sample.php

cat << EOF > wp-config.php
<?php
define( 'DB_NAME', '$DATABASE_NAME' );
define( 'DB_USER', 'wpuser' );
define( 'DB_PASSWORD', '$DATABASE_PASSWORD' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );
\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF


## NGINX ##
apt-get -y install nginx

cat << EOF > /etc/nginx/sites-available/wordpress.conf
server {
            listen 80;
            root /var/www/html/wordpress;
            index index.php index.html;
            server_name $NGINX_SERVER_NAME;

            access_log /var/log/nginx/SUBDOMAIN.access.log;
            error_log /var/log/nginx/SUBDOMAIN.error.log;

            location / {
                         try_files \$uri \$uri/ =404;
            }

            location ~ \.php\$ {
                         include snippets/fastcgi-php.conf;
                         fastcgi_pass unix:/run/php/php8.3-fpm.sock;
            }

            location ~ /\.ht {
                         deny all;
            }

            location = /favicon.ico {
                         log_not_found off;
                         access_log off;
            }

            location = /robots.txt {
                         allow all;
                         log_not_found off;
                         access_log off;
           }

            location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
                         expires max;
                         log_not_found off;
           }
}
EOF

ln -s /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/wordpress.conf
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
