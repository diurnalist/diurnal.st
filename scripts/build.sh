#!/usr/bin/env bash

export JEKYLL_VERSION=4.1.0
export JEKYLL_ENVIRONMENT=production

dir="${1:-_site}"
docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  --volume="diurnal_st_gems:/usr/local/bundle" \
  jekyll/jekyll:$JEKYLL_VERSION \
  jekyll build --destination "$dir" \
  "$@"
