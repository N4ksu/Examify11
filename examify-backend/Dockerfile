#This code below is for Deployment/Production
FROM php:8.4-cli

RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev libpng-dev libonig-dev libxml2-dev libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN composer install --no-dev --optimize-autoloader

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 10000

CMD sh -c "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=${PORT:-10000}"


# #This code below is for local deployment
# FROM php:8.4-fpm

# RUN apt-get update && apt-get install -y \
#     git curl zip unzip libzip-dev libpng-dev libonig-dev libxml2-dev libpq-dev \
#     && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip

# COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# WORKDIR /var/www

# COPY . .

# RUN composer install --no-dev --optimize-autoloader

# RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# EXPOSE 9000
# CMD ["php-fpm"]
