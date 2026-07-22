#!/bin/sh -e

case "$1" in

  web)
    if [[ -z "$SECRET_KEY_BASE" ]] || [[ "$SECRET_KEY_BASE" == "changeme" ]];
    then
      export SECRET_KEY_BASE=$(openssl rand -hex 64)
    fi

    exec bundle exec puma -C config/puma.rb
  ;;

  *)
    exec "$@"
  ;;

esac
