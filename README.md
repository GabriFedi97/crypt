# crypt

[![Version](https://img.shields.io/badge/version-v0.1.1-brightgreen.svg)](https://github.com/VirtusLab/crypt/releases/tag/v0.1.1)
[![Travis CI](https://img.shields.io/travis/VirtusLab/crypt.svg)](https://travis-ci.org/VirtusLab/crypt)
[![Github All Releases](https://img.shields.io/github/downloads/VirtusLab/crypt/total.svg)](https://github.com/VirtusLab/crypt/releases)
[![Go Report Card](https://goreportcard.com/badge/github.com/VirtusLab/crypt "Go Report Card")](https://goreportcard.com/report/github.com/VirtusLab/crypt)

Universal cryptographic tool with AWS KMS, GCP KMS and Azure Key Vault support.

* [Installation](README.md#installation)
  * [Binaries](README.md#binaries)
  * [Via Go](README.md#via-go)
  * [Via homebrew (macOS)](README.md#via-homebrew)
* [Usage](README.md#usage)
  * [Encryption using AWS KMS](README.md#encryption-using-aws-kms)
  * [Encryption using GCP KMS](README.md#encryption-using-gcp-kms)
  * [Encryption using Azure Key Vault](README.md#encryption-using-azure-key-vault)
* [Development](README.md#development)
* [Contribution](README.md#contribution)


## Maturity

Provider        | Maturity
----------------|---------
AWS KMS         | `beta`
GCP KMS         | `alpha`
Azure Key Vault | `alpha`

## Installation

#### Binaries

For binaries please visit the [Releases Page](https://github.com/VirtusLab/crypt/releases).

#### Via Go

    $ go get github.com/VirtusLab/crypt
    
#### Via Homebrew

    # Will be installed as cloudcrypt
    $ brew tap virtuslab/cloud && brew install cloudcrypt

## Usage

    NAME:
       crypt - Universal cryptographic tool with AWS KMS, GCP KMS and Azure Key Vault support

    USAGE:
       crypt [global options] command [command options] [arguments...]

    VERSION:
       v0.1.1-5d53a581

    AUTHOR:
       VirtusLab

    COMMANDS:
         encrypt, enc, en, e  Encrypts files and/or strings
         decrypt, dec, de, d  Decrypts files and/or strings
         help, h              Shows a list of commands or help for one command

    GLOBAL OPTIONS:
       --debug, -d    run in debug mode
       --help, -h     show help
       --version, -v  print the version

### Supported encryption backends

Currently, `crypt` supports the following encryption backends:

- [getting started with AWS](docs/getting-started-aws.md)
- [getting started with Azure](docs/getting-started-azure.md)
- [getting started with GCP](docs/getting-started-gcp.md)

## Development

    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

    mkdir -p $GOPATH/src/github.com/VirtusLab
    cd $GOPATH/src/github.com/VirtusLab
    git clone git@github.com:VirtusLab/crypt.git
    cd crypt

    go get -u github.com/golang/dep/cmd/dep
    make all

### Testing

    make test

### Integration testing

Update properties in `Makfile` if necessary and run:

    make integrationtest
    
## Contribution

Feel free to file [issues](https://github.com/VirtusLab/crypt/issues) or [pull requests](https://github.com/VirtusLab/crypt/pulls).    