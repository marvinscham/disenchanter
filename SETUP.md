# Setup

- Install Ruby 3.2.3
- `bundle install`

# Build executable

Uses [ocran](https://github.com/Largo/ocran).

- Run `./scripts/build_main.sh`
- Run `./scripts/build_updater.sh`

# Increment version

- `bumpversion --new-version <version> <major|minor|fix>`