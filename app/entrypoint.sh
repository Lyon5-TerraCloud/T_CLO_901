#!/bin/sh
set -e

echo "Waiting for MySQL at $DB_HOST:$DB_PORT..."

until mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent; do
  sleep 2
done

echo "Database is up, running migrations and seeders..."

php artisan migrate --force
php artisan db:seed --force

echo "Starting Apache..."
exec apache2-foreground
