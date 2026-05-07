BINARY_DIR := build
VERSION ?= v3.0.1
GOFLAGS ?= -mod=mod
ICON := assets/BE_icon.ico
RSRC := go run github.com/akavel/rsrc@latest

.PHONY: build build-windows test vet check-translations cleanup-translations report-missing-translations clean

build:
	go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter ./cmd/disenchanter
	go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter_up ./cmd/disenchanter_up

build-windows:
	mkdir -p $(BINARY_DIR)
	$(RSRC) -ico $(ICON) -o cmd/disenchanter/rsrc_windows_amd64.syso
	$(RSRC) -ico $(ICON) -o cmd/disenchanter_up/rsrc_windows_amd64.syso
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter.exe ./cmd/disenchanter
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter_up.exe ./cmd/disenchanter_up
	rm -f cmd/disenchanter/rsrc_windows_amd64.syso cmd/disenchanter_up/rsrc_windows_amd64.syso

test:
	go test -coverprofile=coverage.out ./internal/app

vet:
	go vet ./...

check-translations:
	go run ./scripts/check-translations

cleanup-translations:
	go run ./scripts/check-translations --remove

report-missing-translations:
	go run ./scripts/check-translations --report-missing

clean:
	rm -rf $(BINARY_DIR)
	rm -f cmd/disenchanter/rsrc_windows_amd64.syso cmd/disenchanter_up/rsrc_windows_amd64.syso
