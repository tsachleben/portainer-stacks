#!/bin/sh

cp example.env .env
composer install --no-dev --optimize-autoloader

php artisan key:generate --force

php artisan p:environment:setup
php artisan p:environment:database
php artisan p:environment:smtp

php artisan migrate --seed --force

crontab -e <<< EOF
* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1
EOF
