FROM ruby:4.0.6-alpine

ARG SOURCE_COMMIT
ARG ALPINE_MIRROR=https://mirrors.cernet.edu.cn/alpine
# 主镜像源同步滞后(索引已更新但包文件 404)时的兜底源,第 3 次重试起切换
ARG ALPINE_FALLBACK_MIRROR=https://mirrors.aliyun.com/alpine
ENV SOURCE_COMMIT=$SOURCE_COMMIT

ENV PORT=8080
ENV SSL_PORT=8443
ENV SECRET_KEY_BASE=changeme
ENV RAILS_ENV=production

EXPOSE $PORT
EXPOSE $SSL_PORT

WORKDIR /app

ADD . .

RUN set -eux; \
    cp /etc/apk/repositories /tmp/repositories.orig; \
    if [ -n "$ALPINE_MIRROR" ]; then \
      sed -i "s#https\?://dl-cdn.alpinelinux.org/alpine#$ALPINE_MIRROR#g" /etc/apk/repositories; \
    fi; \
    packages="build-base zlib-dev tzdata openssl-dev shared-mime-info libc6-compat"; \
    installed=0; \
    for i in 1 2 3 4; do \
      echo "--- apk add attempt $i ---"; \
      if [ "$i" -ge 3 ] && [ -n "$ALPINE_FALLBACK_MIRROR" ]; then \
        echo "switching to fallback mirror: $ALPINE_FALLBACK_MIRROR"; \
        sed "s#https\?://dl-cdn.alpinelinux.org/alpine#$ALPINE_FALLBACK_MIRROR#g" /tmp/repositories.orig > /etc/apk/repositories; \
      fi; \
      if apk add --no-cache --no-progress --timeout 60 $packages; then installed=1; break; fi; \
      echo "apk add attempt $i failed"; \
      sleep $((i * 5)); \
    done; \
    [ "$installed" = 1 ] || exit 1; \
    rm -rf /var/cache/apk/* /tmp/repositories.orig \
 && gem install bundler \
 && bundle config set without "development test" \
 && bundle install \
 && bundle exec rails assets:precompile \
 && addgroup -S app && adduser -S app -G app -h /app \
 && chown -R app:app /app \
 && chown -R app:app /usr/local/bundle

USER app

ADD docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["web"]

