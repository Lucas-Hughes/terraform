# Make will use bash instead of sh
SHELL := /usr/bin/env bash

TERRAFORM_VERSION := 1.5.0

# Install terraform
.PHONY: mac_terraform_install
mac_terraform_install:
	wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip
	unzip terraform_${TERRAFORM_VERSION}_darwin_amd64.zip
	mv terraform /usr/local/bin/
	rm terraform_${TERRAFORM_VERSION}_darwin_amd64.zip

# Install Mac commands needed for running pre-commit (coreutils is for realpath)
.PHONY: mac_pre_commit_install
mac_pre_commit_install:
	brew install coreutils pre-commit terraform-docs tfsec tflint

# Install all Mac Requirement to run Terraform and Pre-commit locally
.PHONY: install_all_mac_prereqs
install_all_mac_prereqs:
	make mac_terraform_install mac_pre_commit_install

# Run Pre-commit
.PHONY: pre_commit
pre_commit: format lint docs security validate clean

# Format code
.PHONY: format
format:
	terraform fmt --recursive

# Lint code
.PHONY: lint
lint:
	tflint --recursive

# Generate documentation
.PHONY: docs
docs:
	terraform-docs -c .terraform-docs.yml --recursive .

# Security checks
.PHONY: security
security:
	tfsec . -s

# Validate all modules
.PHONY: validate
validate:
	for dir in $$(find modules -type d -maxdepth 2 -not -path "modules/*/"); do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Validating in directory: $$dir"; \
			( cd $$dir && terraform init -backend=false && terraform validate ); \
		fi \
	done

# Delete all .terraform directories
.PHONY: clean
clean:
	for dir in $$(find . -type d -name ".terraform"); do \
		rm -rf "$$dir"; \
	done
	for dir in $$(find . -type f -name ".terraform.lock.hcl"); do \
		rm -rf "$$dir"; \
	done