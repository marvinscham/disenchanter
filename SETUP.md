# Setup

- Install Go 1.23 or open the repository in the included devcontainer.
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

## Increment version

Update the version constant in `cmd/disenchanter/main.go`, then tag the release with the same `vMAJOR.MINOR.PATCH` version.
