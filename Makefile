.PHONY: help init fmt fmt-check lint test clean \
        build-generic build-intel build-amd build-nvidia \
        build-k8s-generic build-k8s-intel build-k8s-amd build-k8s-nvidia

SHELL := /usr/bin/env bash
PACKER := packer

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Packer plugins
	@cd packer && $(PACKER) init .

fmt: ## Format Packer HCL configurations
	@cd packer && $(PACKER) fmt .

fmt-check: ## Verify Packer HCL formatting
	@cd packer && $(PACKER) fmt -check .

lint: fmt-check ## Run packer validate, shellcheck, and yamllint
	@echo "==> Validating Packer configuration..."
	@cd packer && $(PACKER) validate .
	@echo "==> Running ShellCheck on provisioner scripts..."
	@shellcheck packer/provisioners/*.sh
	@if command -v yamllint >/dev/null 2>&1; then \
		echo "==> Running Yamllint..."; \
		yamllint -d "{extends: default, rules: {line-length: {max: 140}, document-start: disable}}" .github/ packer/http/; \
	fi
	@echo "==> All lint checks passed successfully."

test: ## Run automated configuration and consistency tests
	@pytest tests/ -v

build-generic: init ## Build base-generic image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-generic.qemu.image" .

build-intel: init ## Build base-intel image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-intel.qemu.image" .

build-amd: init ## Build base-amd image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-amd.qemu.image" .

build-nvidia: init ## Build base-nvidia image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-nvidia.qemu.image" .

build-k8s-generic: init ## Build k8s-node-generic image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="k8s-node-generic.qemu.image" .

build-k8s-intel: init ## Build k8s-node-intel image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="k8s-node-intel.qemu.image" .

build-k8s-amd: init ## Build k8s-node-amd image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="k8s-node-amd.qemu.image" .

build-k8s-nvidia: init ## Build k8s-node-nvidia image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="k8s-node-nvidia.qemu.image" .

clean: ## Clean up local build artifacts and caches
	@rm -rf output-images/ packer/packer_cache/ .pytest_cache/
	@echo "==> Build artifacts cleaned."
