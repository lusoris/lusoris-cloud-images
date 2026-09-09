# AI & LLM Inference Appliances

The `ai-infer-*` flavors provide turnkey environments for high-throughput Large Language Model (LLM) and multimodal inference serving using **vLLM**, **Ollama**, or Hugging Face TGI.

---

## Available Flavors

- **`ai-infer-nvidia`**: Mainstream NVIDIA 565 driver (`565.77`) with CUDA 12.8 for Turing, Ampere, and Ada GPUs (RTX 3090, RTX 4090, A100, L40S).
- **`ai-infer-nvidia-bleeding`**: Bleeding-edge NVIDIA 615 driver (`615.71.09`) with CUDA 13.4 optimized for Blackwell GPUs (GeForce RTX 5090, B200) with native MXFP4/FP8 quantization acceleration.

---

## System Optimizations

- **Transparent Hugepages & Memory Overcommit**: `transparent_hugepage=always` kernel cmdline, `vm.overcommit_memory = 1`, and `vm.max_map_count = 1048576` tuned for heavy PyTorch tensors and KV-cache allocations.
- **NUMA Interleaving**: Pre-installed `numactl` and `libnuma-dev` for multi-socket CPU/GPU memory binding and core affinity.
- **Cache Persistence**: Standardized persistent cache directories at `/var/lib/models/huggingface` (`HF_HOME`) and `/var/lib/models/ollama` (`OLLAMA_MODELS`).
- **NVIDIA CDI**: Pre-configured NVIDIA Container Toolkit with Container Device Interface (CDI) specifications generated at `/etc/cdi/nvidia.yaml`.

---

## Launching vLLM

```bash
docker run --runtime nvidia --gpus all \
  -v /var/lib/models/huggingface:/root/.cache/huggingface \
  -p 8000:8000 --ipc=host \
  vllm/vllm-openai:latest \
  --model meta-llama/Llama-3.3-70B-Instruct
```

