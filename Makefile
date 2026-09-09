.PHONY: help init fmt fmt-check lint test clean compress docs-serve docs-build \
        build-base-generic build-base-intel build-base-amd \
        build-docker-generic build-docker-intel build-docker-amd build-docker-nvidia \
        build-podman-generic \
        build-k8s-generic build-k8s-intel build-k8s-amd build-k8s-nvidia \
        build-ai-infer-nvidia \
        build-generic build-intel build-amd build-nvidia

SHELL := /usr/bin/env bash
PACKER := packer

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}'

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
		yamllint -c .yamllint.yml .github/ packer/http/; \
	fi
	@echo "==> All lint checks passed successfully."

test: ## Run automated configuration, SSOT, and privacy tests
	@pytest tests/ -v

compress: ## Compress generated output images with zstd
	@echo "==> Compressing output images with zstd..."
	@find output-images -type f -name '*.qcow2' -exec zstd -T0 -19 --rm {} +
	@echo "==> Compression complete."

docs-serve: ## Serve documentation portal locally via mkdocs
	@mkdocs serve

docs-build: ## Build documentation portal strictly
	@mkdocs build --strict

# Base Flavors
build-base-generic: init ## Build base-generic image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-generic.qemu.image" .

build-base-intel: init ## Build base-intel image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-intel.qemu.image" .

build-base-amd: init ## Build base-amd image via local QEMU/KVM
	@cd packer && $(PACKER) build -only="base-amd.qemu.image" .

# Docker & Container Appliances
build-docker-generic: init ## Build docker-generic appliance
	@cd packer && $(PACKER) build -only="docker-generic.qemu.image" .

build-docker-intel: init ## Build docker-intel appliance (QuickSync)
	@cd packer && $(PACKER) build -only="docker-intel.qemu.image" .

build-docker-amd: init ## Build docker-amd appliance (ROCm)
	@cd packer && $(PACKER) build -only="docker-amd.qemu.image" .

build-docker-nvidia: init ## Build docker-nvidia appliance (CDI)
	@cd packer && $(PACKER) build -only="docker-nvidia.qemu.image" .

build-podman-generic: init ## Build podman-generic appliance (Quadlet)
	@cd packer && $(PACKER) build -only="podman-generic.qemu.image" .

# Kubernetes Node Flavors
build-k8s-generic: init ## Build k8s-node-generic image
	@cd packer && $(PACKER) build -only="k8s-node-generic.qemu.image" .

build-k8s-intel: init ## Build k8s-node-intel image
	@cd packer && $(PACKER) build -only="k8s-node-intel.qemu.image" .

build-k8s-amd: init ## Build k8s-node-amd image
	@cd packer && $(PACKER) build -only="k8s-node-amd.qemu.image" .

build-k8s-nvidia: init ## Build k8s-node-nvidia image
	@cd packer && $(PACKER) build -only="k8s-node-nvidia.qemu.image" .

# AI Inference Appliance
build-ai-infer-nvidia: init ## Build ai-infer-nvidia host
	@cd packer && $(PACKER) build -only="ai-infer-nvidia.qemu.image" .

# Backwards compatibility aliases
build-generic: build-base-generic
build-intel: build-base-intel
build-amd: build-base-amd
build-nvidia: build-docker-nvidia

clean: ## Clean up local build artifacts and caches
	@rm -rf output-images/ packer/packer_cache/ .pytest_cache/ site/
	@echo "==> Build artifacts cleaned."
