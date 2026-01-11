# EmergencyBox DD-WRT Emulation Environment
# Mimics ASUS RT-AC68U running DD-WRT with Entware

FROM alpine:3.18

# Metadata
LABEL description="DD-WRT RT-AC68U emulation for EmergencyBox testing"
LABEL version="1.0"

# Install packages similar to DD-WRT Entware environment
# Using Alpine to keep it lightweight like router environment
RUN apk update && apk add --no-cache \
    php82 \
    php82-fpm \
    php82-cgi \
    php82-sqlite3 \
    php82-fileinfo \
    php82-session \
    php82-json \
    php82-mbstring \
    lighttpd \
    sqlite \
    bash \
    busybox \
    curl \
    && rm -rf /var/cache/apk/*

# Create directory structure similar to DD-WRT router
RUN mkdir -p /opt/share/www \
    && mkdir -p /opt/share/www/uploads/{emergency,media,documents,general} \
    && mkdir -p /opt/share/data \
    && mkdir -p /opt/var/log/lighttpd \
    && mkdir -p /opt/etc/lighttpd \
    && mkdir -p /tmp

# Set permissions (router typically has looser permissions)
RUN chmod -R 777 /opt/share/www/uploads \
    && chmod -R 755 /opt/share/data \
    && chmod -R 755 /opt/var/log/lighttpd

# Copy EmergencyBox files
COPY www /opt/share/www
COPY config/php.ini /etc/php82/php.ini
COPY EMUL/lighttpd-emul.conf /etc/lighttpd/lighttpd.conf

# Create a startup script
COPY EMUL/start-services.sh /start-services.sh
RUN chmod +x /start-services.sh

# Expose port 80 (router web interface)
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Set working directory
WORKDIR /opt/share/www

# Start services
CMD ["/start-services.sh"]
