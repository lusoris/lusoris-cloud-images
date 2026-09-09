---
name: test-image
description: Run automated test suite to verify configuration integrity, lint compliance, and image validity
---

# /test-image

Execute the test suite to ensure all image definitions and provisioner scripts satisfy quality gates.

## Usage

```bash
# Run pytest verification
make test

# Or directly
pytest tests/ -v
```
