# AI & LLM Inference Appliance (`ai-infer-nvidia`)

The `ai-infer-nvidia` flavor provides a turnkey environment for high-throughput Large Language Model (LLM) serving using **vLLM**, **Ollama**, or Hugging Face TGI.

## System Optimizations

- **Transparent Hugepages**: `vm.overcommit_memory = 1` and `vm.max_map_count = 1048576` tuned for deep learning memory allocators.
- **NUMA Interleaving**: Pre-installed `numactl` and `libnuma-dev` for multi-socket CPU/GPU memory binding.
- **Cache Persistence**: Standardized persistent cache directories at `/var/lib/models/huggingface` (`HF_HOME`) and `/var/lib/models/ollama` (`OLLAMA_MODELS`).
- **NVIDIA CDI**: Pre-configured NVIDIA Container Toolkit with Container Device Interface (CDI) v0.6+ specifications.

## Launching vLLM
```bash
docker run --runtime nvidia --gpus all \
  -v /var/lib/models/huggingface:/root/.cache/huggingface \
  -p 8000:8000 --ipc=host \
  vllm/vllm-openai:latest \
  --model meta-llama/Llama-3.3-70B-Instruct
```
