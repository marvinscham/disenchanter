# Setup

- Install Go 1.23 or open the repository in the included devcontainer (recommended).
- Download dependencies with `go mod download`.

## Build executable

Builds both Windows executables from any supported Go host:

```bash
make build-windows
```

Outputs:

- `build/disenchanter.exe`
- `build/disenchanter_up.exe`

## i18n

Translation YAML files live in `i18n/`. The executable embeds an English fallback and loads repository translation files when present during development.

## Releases

Workflow:

- Increment version using bumpversion: `bumpversion <major|minor|patch>`
    - For custom versioning or other usecases: `bumpversion --new-version 1.2.3-beta ff`
- Push the commit and tag generated this way: `git push && git push --tags`
- CI will build the executables, create a release, and attach the files to it
