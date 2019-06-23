# diurnal.st

This is the source code for https://diurnal.st

## Versions

Previous version of the site are located at Git tags, e.g. "v1".

## Development

Run `./scripts/serve.sh` to start a local server. The server will automatically rebuild the static site as source files are changed.

## Releasing

This is a static site, so once it is built into a series of static assets, it can be hosted in a variety of ways. One option is to build the site (`./scripts/build.sh` assists with this) after pulling latest changes via Git. Another option is publishing a new tarball of the static files and pushing it up somewhere.

