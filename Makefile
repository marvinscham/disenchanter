BINARY_DIR := build
VERSION ?= v3.0.0
GOFLAGS ?= -mod=mod
export GOFLAGS

.PHONY: build build-windows test vet clean

build:
	go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter ./cmd/disenchanter
	go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter_up ./cmd/disenchanter_up

build-windows:
	mkdir -p $(BINARY_DIR)
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter.exe ./cmd/disenchanter
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -buildvcs=false -ldflags "-s -w" -o $(BINARY_DIR)/disenchanter_up.exe ./cmd/disenchanter_up

test:
	go test ./...

vet:
	go vet ./...

clean:
	rm -rf $(BINARY_DIR)
