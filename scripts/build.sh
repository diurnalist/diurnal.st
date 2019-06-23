#!/usr/bin/env bash

export JEKYLL_VERSION=3.8
export JEKYLL_ENVIRONMENT=production

dir="${1:-_site}"
docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  jekyll/minimal:$JEKYLL_VERSION \
  jekyll build --destination "$dir" \
  "$@"
