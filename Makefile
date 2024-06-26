# Copyright 2019 Cornelius Weig
# Copyright 2024 The kubectl-plugin Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export GO111MODULE ?= on
export CGO_ENABLED ?= 0

PROJECT   ?= ketall
REPOPATH  ?= github.com/kubectl-plugin/$(PROJECT)
COMMIT    := $(shell git rev-parse HEAD)
VERSION   ?= $(shell git describe --always --tags --dirty)
GOOS      ?= $(shell go env GOOS)
GOPATH    ?= $(shell go env GOPATH)

BUILDDIR  := bin
CHECKSUMS  := $(patsubst %,%.sha256,$(ASSETS) $(ASSETSKREW))

VERSION_PACKAGE := $(REPOPATH)/internal/version

DATE_FMT = %Y-%m-%dT%H:%M:%SZ
ifdef SOURCE_DATE_EPOCH
    # GNU and BSD date require different options for a fixed date
    BUILD_DATE ?= $(shell date -u -d "@$(SOURCE_DATE_EPOCH)" "+$(DATE_FMT)" 2>/dev/null || date -u -r "$(SOURCE_DATE_EPOCH)" "+$(DATE_FMT)" 2>/dev/null)
else
    BUILD_DATE ?= $(shell date "+$(DATE_FMT)")
endif
GO_LDFLAGS :='-s -w -linkmode=internal "-extldflags=-static-pie"
GO_LDFLAGS += -X $(VERSION_PACKAGE).version=$(VERSION)
GO_LDFLAGS += -X $(VERSION_PACKAGE).buildDate=$(BUILD_DATE)
GO_LDFLAGS += -X $(VERSION_PACKAGE).gitCommit=$(COMMIT)'

ifdef ZOPFLI
  COMPRESS:=zopfli -c
else
  COMPRESS:=gzip --best -k -c
endif

GO_FILES  := $(shell find . -type f -name '*.go')

.PHONY: test
test:
	go test ./...

.PHONY: help
help:
	@echo 'Valid make targets:'
	@echo '  - all:      build binaries for all supported platforms'
	@echo '  - clean:    clean up build directory'
	@echo '  - coverage: run unit tests with coverage'
	@echo '  - deploy:   build artifacts for a new deployment'
	@echo '  - dev:      build the binary for the current platform'
	@echo '  - dist:     create a tar archive of the source code'
	@echo '  - help:     print this help'
	@echo '  - lint:     run golangci-lint'
	@echo '  - test:     run unit tests'
	@echo '  - build-ketall:   build binaries for all supported platforms'
	@echo '  - build-get-all:  build binaries for all supported platforms'

.PHONY: coverage
coverage: $(BUILDDIR)
	go test -coverprofile=$(BUILDDIR)/coverage.txt -covermode=atomic ./...

.PHONY: all
all: lint test dev

.PHONY: dev
dev: CGO_ENABLED := 1
dev: GO_LDFLAGS := $(subst -s -w,,$(GO_LDFLAGS))
dev:
	go build -race -ldflags $(GO_LDFLAGS) -o ketall main.go

build-ketall: $(GO_FILES) $(BUILDDIR)
	CGO_ENABLED=0 go build -o $(BUILDDIR)/ketall -v -x -trimpath -tags='osusergo,netgo,static,static_build' -buildmode=pie -ldflags=$(GO_LDFLAGS)

build-kubectl-get_all: $(GO_FILES) $(BUILDDIR)
	CGO_ENABLED=0 go build -o $(BUILDDIR)/kubectl-get_all -v -x -trimpath -tags='getall,osusergo,netgo,static,static_build' -buildmode=pie -ldflags=$(GO_LDFLAGS)

.PHONY: lint
lint:
	hack/run_lint.sh

$(BUILDDIR):
	mkdir -p "$@"

.PHONY: deploy
deploy: $(CHECKSUMS)
	$(RM) $(BUILDDIR)/LICENSE

.PHONY: dist
dist: $(DISTFILE)

.PHONY: clean
clean:
	$(RM) -r $(BUILDDIR) ketall
