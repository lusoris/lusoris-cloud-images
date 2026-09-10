---
name: test-image
description: Run automated test suite to verify configuration integrity, lint compliance, and image validity
---

# /test-image

Execute the test suite to ensure all image definitions and provisioner scripts satisfy quality gates.

## Usage

```bash
# Run automated Go and Python test suite
make test

# Run Go benchmarks with memory allocation metrics
make test-bench

# Run Go coverage analysis
make test-coverage

# Run full enterprise verification suite (lints, tests, live docker, benchmarks)
make test-all
```
