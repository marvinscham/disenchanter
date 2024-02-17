# Versioning

Disenchanter's versioning is based on [Semantic Versioning](https://semver.org/).

The version number is structured as `MAJOR.MINOR.PATCH`:
- `MAJOR` version is incremented on changes breaking the current usage flow
- `MINOR` version is incremented on backwards compatible functionality additions
- `PATCH` version is incremented on backwards compatible bug fixes

Notable changes in documentation will be documented in the [changelog](./CHANGELOG.md) for historical insights.

## Versioning Workflow

Versioning is handled via [bumpversion](https://github.com/peritus/bumpversion), configured in `.bumpversion.cfg`.