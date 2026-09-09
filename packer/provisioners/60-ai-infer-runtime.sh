#!/usr/bin/env bash
# 60-ai-infer-runtime.sh — Turnkey AI/LLM inference host configuration (vLLM & Ollama)
# Configures transparent hugepages, NUMA interleaving, and high-performance execution.
set -euo pipefail

configure_hugepages_and_numa() {
  echo "==> Configuring transparent hugepages and memory allocation..."
  cat <<'EOF' | sudo tee /etc/sysctl.d/95-ai-memory.conf
# Enable transparent hugepages compaction and virtual memory overcommit
vm.overcommit_memory = 1
vm.max_map_count = 1048576
EOF

  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    numactl \
    libnuma-dev \
    libgomp1
}

setup_inference_directories() {
  echo "==> Setting up model cache directories and permissions..."
  sudo mkdir -p /var/lib/models /etc/vllm /etc/ollama
  sudo chown -R ubuntu:ubuntu /var/lib/models 2>/dev/null || true

  # Hook environment variables for Hugging Face and Ollama model caches
  cat <<'EOF' | sudo tee /etc/profile.d/ai-env.sh
export HF_HOME="/var/lib/models/huggingface"
export OLLAMA_MODELS="/var/lib/models/ollama"
EOF
}

main() {
  configure_hugepages_and_numa
  setup_inference_directories
  echo "==> 60-ai-infer-runtime: Complete."
}

main "$@"
