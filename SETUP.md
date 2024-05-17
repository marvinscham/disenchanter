# Setup

- Install Ruby 3.2.3
- `bundle install`

## Build executable

Uses [ocran](https://github.com/Largo/ocran).

```bash
./scripts/build.sh
```

## i18n

The gem `i18n-tasks` is used for quality assurance for i18n.

Useful commands:

```bash
bundle exec i18n-tasks health
```
```bash
bundle exec i18n-tasks normalize
```
```bash
bundle exec i18n-tasks unused
```
```bash
bundle exec i18n-tasks remove-unused
```

## Increment version

- `bumpversion --new-version <version> <major|minor|fix>`