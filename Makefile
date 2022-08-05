GOARCH = amd64

UNAME = $(shell uname -s)

ifndef OS
	ifeq ($(UNAME), Linux)
		OS = linux
	else ifeq ($(UNAME), Darwin)
		OS = darwin
	endif
endif

.DEFAULT_GOAL := all

all: fmt build start

build:
	CGO_ENABLED=0 GOOS=$(OS) GOARCH="$(GOARCH)" go build -o vault/plugins/vault-plugin-kuma cmd/vault-plugin-kuma/main.go

start:
	vault server -dev -dev-root-token-id=root -dev-plugin-dir=./vault/plugins

restart_vault_shipyard:
	shipyard taint container.vault && shipyard run --no-browser ./shipyard

enable:
	vault secrets enable -path=kuma vault-plugin-kuma || true

	vault write kuma/config \
		allowed_roles="kuma-role" \
    url=" kuma-cp.container.shipyard.run:5681" \
		token="$(KUMA_TOKEN)"

	# How to differentiate between user token role and dataplane role
	vault write kuma/roles/kuma-role \
    mesh=default \
		tags="kuma.io/service=backend,kuma.io/service=backend-admin"
    ttl="5m" \
    max_ttl="24h"
clean:
	rm -f ./vault/plugins/*

tests: build
	cd functional_tests && go run main.go

fmt:
	go fmt $$(go list ./...)

.PHONY: build clean fmt start enable
