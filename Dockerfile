FROM ubuntu:14.04
MAINTAINER Yuichiro Mukai <y.iky917@gmail.com>

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -yq --force-yes build-essential wget curl git ssh nginx nodejs-legacy npm mysql-client supervisor

RUN apt-get install -yq --force-yes  php5-cli php5 php5-fpm php5-mysql php5-curl php5-mcrypt php5-memcached && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN php5enmod mcrypt

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN mkdir -p /app
WORKDIR /app

ADD ./application/database /app/database
ADD ./application/tests /app/tests
ADD ./application/composer.json /app/composer.json
RUN composer install --no-scripts

ADD ./application /app
RUN php artisan clear-compiled
RUN php artisan optimize

RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

RUN chown -R www-data:www-data /app

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ADD docker/nginx-site.conf /etc/nginx/sites-available/default

ADD docker/supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

