FROM php:8.2-fpm

# 安装系统依赖，包括WebP支持
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# 安装 PHP 扩展，启用WebP支持
RUN docker-php-ext-configure gd --with-webp --with-jpeg --with-freetype \
    && docker-php-ext-configure intl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip opcache

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 安装 dos2unix 工具(用于转换 Windows 换行符)
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 配置 Nginx
RUN echo 'server {\n\
    listen 80;\n\
    root /app/public;\n\
    location / {\n\
        try_files $uri /index.php$is_args$args;\n\
    }\n\
    location ~ ^/index\.php(/|$) {\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_split_path_info ^(.+\.php)(/.*)$;\n\
        include fastcgi_params;\n\
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;\n\
        fastcgi_param DOCUMENT_ROOT $realpath_root;\n\
        fastcgi_read_timeout 300;\n\
        fastcgi_connect_timeout 300;\n\
        fastcgi_send_timeout 300;\n\
        internal;\n\
    }\n\
    location ~ \.php$ {\n\
        return 404;\n\
    }\n\
}' > /etc/nginx/sites-available/default

# 配置 Supervisor
RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:php-fpm]\n\
command=/usr/local/sbin/php-fpm\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:nginx]\n\
command=/usr/sbin/nginx -g "daemon off;"\n\
autostart=true\n\
autorestart=true' > /etc/supervisor/conf.d/supervisord.conf

# 创建启动脚本，自动修复权限和换行符问题
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# 修复 bin/console 换行符和权限\n\
if [ -f /app/bin/console ]; then\n\
    dos2unix /app/bin/console 2>/dev/null || sed -i "s/\r$//" /app/bin/console\n\
    chmod +x /app/bin/console\n\
fi\n\
\n\
# 创建必要的目录\n\
mkdir -p /app/var/cache /app/var/log /app/public/media /app/config\n\
\n\
# 修复目录权限\n\
chown -R www-data:www-data /app/var /app/public/media /app/config 2>/dev/null || true\n\
chmod -R 775 /app/var /app/public/media 2>/dev/null || true\n\
\n\
# 启动 supervisord\n\
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf\n\
' > /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

CMD ["/usr/local/bin/docker-entrypoint.sh"]
