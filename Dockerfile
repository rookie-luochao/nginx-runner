FROM nginx:alpine-slim

# Import environment variables
ENV PROJECT_VERSION=v0.0.0
ENV ENV=prod
ENV APP_CONFIG=""

# use memory cache
RUN sed -i "/http {/a \\    proxy_cache_path /etc/nginx/cache levels=1:1 keys_zone=static_memory_cache:10m max_size=100m inactive=1d use_temp_path=off;" /etc/nginx/nginx.conf
# Copy nginx config
COPY conf-base.template /etc/nginx/conf.d/conf-base.template
# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
# execute entrypoint
CMD ["/entrypoint.sh"]