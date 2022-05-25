# Setup variables for the Makefile
NAME=crypt
PKG=github.com/VirtusLab/crypt

# Import config
# You can change the default config with `make config="config_special.env" build`
config ?= config.env
include $(config)

# Set POSIX sh for maximum interoperability
SHELL := /bin/sh
PATH  := $(GOPATH)/bin:$(PATH)

# Set an output prefix, which is the local directory if not specified
PREFIX?=$(shell pwd)

# Set the main.go path for go command
#BUILD_PATH := ./cmd/$(NAME)
BUILD_PATH := .

# Set any default go build tags
BUILDTAGS :=

# Set the build dir, where built cross-compiled binaries will be output
BUILDDIR := ${PREFIX}/cross

# Populate version variables
# Add to compile time flags
VERSION := $(shell cat VERSION.txt)
GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
GITIGNOREDBUTTRACKEDCHANGES := $(shell git ls-files -c -i --exclude-standard)
ifneq ($(GITUNTRACKEDCHANGES),)
    GITCOMMIT := $(GITCOMMIT)-dirty
endif
ifneq ($(GITIGNOREDBUTTRACKEDCHANGES),)
    GITCOMMIT := $(GITCOMMIT)-dirty
endif

# If we're building from tar.gz released files the .git directory will be missing
# to avoid errors at make status we set the two to null
# this is mainly used in brew formula
ifdef BUILDING_FROM_TGZ
GITCOMMIT=fromsrc
GITUNTRACKEDCHANGES=
GITIGNOREDBUTTRACKEDCHANGES=
endif

CTIMEVAR=-X $(PKG)/version.GITCOMMIT=$(GITCOMMIT) -X $(PKG)/version.VERSION=$(VERSION)
GO_LDFLAGS=-ldflags "-w $(CTIMEVAR)"
GO_LDFLAGS_STATIC=-ldflags "-w $(CTIMEVAR) -extldflags -static"

# List the GOOS and GOARCH to build
GOOSARCHES = darwin/amd64 darwin/arm64 freebsd/amd64 freebsd/386 linux/arm linux/arm64 linux/amd64 linux/386 windows/amd64 windows/386

PACKAGES = $(shell go list -f '{{.ImportPath}}/' ./... | grep -v vendor)

ARGS ?= $(EXTRA_ARGS)

.DEFAULT_GOAL := help

.PHONY: all
all: clean verify build install ## Test, build, install
	@echo "+ $@"

.PHONY: init
init: ## Initializes go tools this Makefile uses: goimports, checkmake
	@echo "+ $@"
	go get -u golang.org/x/tools/cmd/goimports
	go get -u github.com/mrtazz/checkmake
	@echo "Initialized tools"

.PHONY: build
build: $(NAME) ## Builds a dynamic executable or package
	@echo "+ $@"

$(NAME): $(wildcard *.go) $(wildcard */*.go) VERSION.txt
	@echo "+ $@"
	go build -tags "$(BUILDTAGS)" ${GO_LDFLAGS} -o $(NAME) $(BUILD_PATH)

.PHONY: static
static: ## Builds a static executable
	@echo "+ $@"
	CGO_ENABLED=0 go build \
				-tags "$(BUILDTAGS) static_build" \
				${GO_LDFLAGS_STATIC} -o $(NAME) $(BUILD_PATH)

.PHONY: fmt
fmt: ## Verifies all files have been `gofmt`ed
	@echo "+ $@"
	@go fmt $(PACKAGES)

.PHONY: goimports
goimports: ## Verifies `goimports` passes
	@echo "+ $@"
	@goimports -l -e $(shell find . -type f -name '*.go' -not -path "./vendor/*")

.PHONY: test
test: ## Runs the go tests
	@echo "+ $@"
	@RUNNING_TESTS=1 go test -v -tags "$(BUILDTAGS) cgo" $(PACKAGES)

.PHONY: integrationtest
integrationtest: export AWS_REGION = $(AWS_REGION_IT)
integrationtest: export AWS_KEY = $(AWS_KEY_IT)
integrationtest: export AWS_PROFILE = $(AWS_PROFILE_IT)
integrationtest: export GCP_PROJECT_ID = $(GCP_PROJECT_ID_IT)
integrationtest: export GCP_LOCATION = $(GCP_LOCATION_IT)
integrationtest: export GCP_KEY_RING = $(GCP_KEY_RING_IT)
integrationtest: export GCP_KEY_IT = $(GCP_KEY_IT_IT)
integrationtest: export GOOGLE_APPLICATION_CREDENTIALS = $(GOOGLE_APPLICATION_CREDENTIALS_IT)
integrationtest: export VAULT_URL = $(VAULT_URL_IT)
integrationtest: export VAULT_KEY = $(VAULT_KEY_IT)
integrationtest: export VAULT_KEY_VERSION = $(VAULT_KEY_VERSION_IT)
integrationtest: ## Runs the integration tests
	@echo "+ $@"
	@go test -v -tags "$(BUILDTAGS) cgo integration" $(PACKAGES)

.PHONY: e2e
e2e: export VAULT_URL = $(VAULT_URL_IT)
e2e: export VAULT_KEY = $(VAULT_KEY_IT)
e2e: export VAULT_KEY_VERSION = $(VAULT_KEY_VERSION_IT)
e2e: build ## Runs the e2e tests
	@echo "+ $@"
	@go test -v -tags "$(BUILDTAGS) cgo e2e" $(PACKAGES)

.PHONY: vet
vet: ## Verifies `go vet` passes
	@echo "+ $@"
	@go vet $(PACKAGES)

.PHONY: install
install: ## Installs the executable
	@echo "+ $@"
	@go install -tags "$(BUILDTAGS)" ${GO_LDFLAGS} $(BUILD_PATH)

.PHONY: run
run: ## Run the executable, you can use EXTRA_ARGS
	@echo "+ $@"
	@go run -tags "$(BUILDTAGS)" ${GO_LDFLAGS} $(BUILD_PATH)/main.go $(ARGS)

define buildpretty
mkdir -p $(BUILDDIR)/$(1)/$(2);
GOOS=$(1) GOARCH=$(2) CGO_ENABLED=0 go build \
		-o $(BUILDDIR)/$(1)/$(2)/$(NAME) \
		-a -tags "$(BUILDTAGS) static_build netgo" \
		-installsuffix netgo ${GO_LDFLAGS_STATIC} $(BUILD_PATH);
md5sum $(BUILDDIR)/$(1)/$(2)/$(NAME) > $(BUILDDIR)/$(1)/$(2)/$(NAME).md5;
sha256sum $(BUILDDIR)/$(1)/$(2)/$(NAME) > $(BUILDDIR)/$(1)/$(2)/$(NAME).sha256;
endef

.PHONY: cross
cross: $(wildcard *.go) $(wildcard */*.go) VERSION.txt ## Builds the cross-compiled binaries, creating a clean directory structure (eg. GOOS/GOARCH/binary)
	@echo "+ $@"
	$(foreach GOOSARCH,$(GOOSARCHES), $(call buildpretty,$(subst /,,$(dir $(GOOSARCH))),$(notdir $(GOOSARCH))))

define buildrelease
GOOS=$(1) GOARCH=$(2) CGO_ENABLED=0 go build \
	 -o $(BUILDDIR)/$(NAME)-$(1)-$(2) \
	 -a -tags "$(BUILDTAGS) static_build netgo" \
	 -installsuffix netgo ${GO_LDFLAGS_STATIC} $(BUILD_PATH);
md5sum $(BUILDDIR)/$(NAME)-$(1)-$(2) > $(BUILDDIR)/$(NAME)-$(1)-$(2).md5;
sha256sum $(BUILDDIR)/$(NAME)-$(1)-$(2) > $(BUILDDIR)/$(NAME)-$(1)-$(2).sha256;
mkdir -p $(BUILDDIR)/$(1)-$(2);
cp ${PREFIX}/LICENSE $(BUILDDIR)/$(1)-$(2);
cp $(BUILDDIR)/$(NAME)-$(1)-$(2) $(BUILDDIR)/$(1)-$(2)/$(NAME);
tar cvzf $(BUILDDIR)/$(NAME)-$(1)-$(2).tar.gz -C $(BUILDDIR) $(1)-$(2);
endef

.PHONY: release
release: $(wildcard *.go) $(wildcard */*.go) VERSION.txt ## Builds the cross-compiled binaries, naming them in such a way for release (eg. binary-GOOS-GOARCH)
	@echo "+ $@"
	$(foreach GOOSARCH,$(GOOSARCHES), $(call buildrelease,$(subst /,,$(dir $(GOOSARCH))),$(notdir $(GOOSARCH))))

.PHONY: verify
verify: fmt vet goimports test ## Runs a fmt, lint, vet, goimports and test

.PHONY: cover
cover: ## Runs go test with coverage
	@echo "" > coverage.txt
	@for d in $(PACKAGES); do \
		RUNNING_TESTS=1 go test -race -coverprofile=profile.out -covermode=atomic "$$d"; \
		if [ -f profile.out ]; then \
			cat profile.out >> coverage.txt; \
			rm profile.out; \
		fi; \
	done;

.PHONY: clean
clean: ## Cleanup any build binaries or packages
	@echo "+ $@"
	go clean
	$(RM) $(NAME) || echo "Couldn't delete, not there."
	$(RM) test$(NAME) || echo "Couldn't delete, not there."
	$(RM) -r $(BUILDDIR) || echo "Couldn't delete, not there."
	$(RM) coverage.txt || echo "Couldn't delete, not there."

.PHONY: spring-clean
spring-clean: ## Cleanup git ignored files (interactive)
	git clean -Xdi

.PHONY: bump-version
BUMP := patch
bump-version: ## Bump the version in the version file. Set BUMP to [ patch | major | minor ]
	@echo "+ $@"
#	go get -u github.com/jessfraz/junk/sembump # update sembump tool
	$(eval NEW_VERSION=$(shell sembump --kind $(BUMP) $(VERSION)))
	@echo "Bumping VERSION.txt from $(VERSION) to $(NEW_VERSION)"
	@echo $(NEW_VERSION) > VERSION.txt
	@echo "Updating version from $(VERSION) to $(NEW_VERSION) in README.md"
	sed -i .bak "s/$(VERSION)/$(NEW_VERSION)/g" README.md
	git add VERSION.txt README.md
	git commit -vseam "Bump version to $(NEW_VERSION)"
	@echo "Run make tag to create and push the tag for new version $(NEW_VERSION)"

.PHONY: tag
tag: ## Create a new git tag to prepare to build a release
	@echo "+ $@"
	git tag -a $(VERSION) -m "$(VERSION)"
	git push origin $(VERSION)

.PHONY: help
help:
	@grep -Eh '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: checkmake
checkmake: ## Check this Makefile
	@echo "+ $@"
	@checkmake Makefile

.PHONY: status
status: ## Shows git and dep status
	@echo "+ $@"
	@echo "Commit: $(GITCOMMIT), VERSION: $(VERSION)"
	@echo
ifneq ($(GITUNTRACKEDCHANGES),)
	@echo "Changed files:"
	@git status --porcelain --untracked-files=no
	@echo
endif
ifneq ($(GITIGNOREDBUTTRACKEDCHANGES),)
	@echo "Ignored but tracked files:"
	@git ls-files -c -i --exclude-standard
	@echo
endif
	@echo "Dependencies:"
	@go list -m all
	@echo
