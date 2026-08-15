FROM ruby:4.0.6-alpine

ARG SOURCE_COMMIT
ARG ALPINE_MIRROR=https://mirrors.cernet.edu.cn/alpine
ENV SOURCE_COMMIT=$SOURCE_COMMIT

ENV PORT=8080
ENV SSL_PORT=8443
ENV SECRET_KEY_BASE=changeme
ENV RAILS_ENV=production

EXPOSE $PORT
EXPOSE $SSL_PORT

WORKDIR /app

ADD . .

RUN if [ -n "$ALPINE_MIRROR" ]; then \
      sed -i "s#https\?://dl-cdn.alpinelinux.org/alpine#$ALPINE_MIRROR#g" /etc/apk/repositories; \
    fi \
 && apk update \
 && for i in 1 2 3; do \
      apk add -v --progress build-base zlib-dev tzdata openssl-dev shared-mime-info libc6-compat && break; \
      echo "apk add attempt $i failed, retrying..."; \
      rm -rf /var/cache/apk/*; \
      [ $i -eq 3 ] && exit 1; \
    done \
 && rm -rf /var/cache/apk/* \
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

