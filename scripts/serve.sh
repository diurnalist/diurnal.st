#!/usr/bin/env bash

export JEKYLL_VERSION=4.1.0
export JEKYLL_ENVIRONMENT=development

dir="${1:-_site}"
docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  --volume="diurnal_st_gems:/usr/local/bundle" \
  --publish="4000:4000" \
  -it jekyll/jekyll:$JEKYLL_VERSION \
  jekyll serve --force_polling --destination "$dir" \
  "$@"
