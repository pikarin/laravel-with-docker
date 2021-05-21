FROM node:14.17.0 AS ui-build
RUN mkdir -p /app/public
COPY package.json webpack.mix.js /app/
COPY resources/css/ /app/resources/css/
COPY resources/js/ /app/resources/js/
COPY resources/sass/ /app/resources/sass/
WORKDIR /app
RUN npm install --silent && npm run prod

FROM php:8.0.6-fpm-buster
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
WORKDIR /var/www
COPY . ./
COPY --from=ui-build /app/public/js/ /var/www/public/js/
COPY --from=ui-build /app/public/css/ /var/www/public/css/
COPY --from=ui-build /app/mix-manifest.json /var/www/public/mix-manifest.json

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential  openssl nginx \
    && chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd imap pdo_mysql zip bcmath soap intl msgpack igbinary redis @composer-2.0.2 \
    && composer install --no-dev

COPY ./docker/php/php.ini /usr/local/etc/php/99-php.ini

COPY ./docker/nginx/conf.d/nginx.conf /etc/nginx/nginx.conf

RUN chown -R www-data:www-data /var/www
RUN chmod -R 775 /var/www

COPY ./docker/start-container /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

EXPOSE 80

ENTRYPOINT ["start-container"]


