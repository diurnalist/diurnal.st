#!/usr/bin/env bash

export JEKYLL_VERSION=3.8

dir="${1:-_site}"
docker run --rm \
  --volume="$PWD:/srv/jekyll" \
  --publish="4000:4000" \
  -it jekyll/minimal:$JEKYLL_VERSION \
  jekyll build --destination "$dir"
