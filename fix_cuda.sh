#!/usr/bin/env bash
# fix_cuda.sh
#
# Fixes: RuntimeError: CUDA error: no kernel image is available for execution on the device
#
# Root cause: The installed PyTorch was compiled for a different GPU compute capability
# than the one present on this RunPod instance (e.g., RTX 4090 / Ada Lovelace needs cu121+).
#
# Usage (run from your RunPod terminal):
#   bash fix_cuda.sh

set -euo pipefail

echo "=== Detecting GPU compute capability ==="
GPU_CC=$(python3 - <<'EOF'
import subprocess, sys
try:
    import torch
    cc = torch.cuda.get_device_capability()
    print(f"{cc[0]}{cc[1]}")
except Exception:
    # fallback: parse nvidia-smi
    result = subprocess.run(
        ["nvidia-smi", "--query-gpu=compute_cap", "--format=csv,noheader"],
        capture_output=True, text=True
    )
    cc = result.stdout.strip().replace(".", "")
    print(cc)
EOF
)

echo "Detected compute capability: ${GPU_CC}"

# Sanitise: keep only digits (handles e.g. "8.9" from older nvidia-smi versions)
GPU_CC_INT=$(echo "${GPU_CC}" | tr -cd '0-9')

if ! [[ "${GPU_CC_INT}" =~ ^[0-9]+$ ]]; then
    echo "WARNING: Could not parse compute capability '${GPU_CC}'. Defaulting to cu118."
    GPU_CC_INT=0
fi

# Choose the correct CUDA wheel index based on compute capability integer
# e.g. compute cap 8.9  → GPU_CC_INT=89
#      compute cap 8.0  → GPU_CC_INT=80
#      compute cap 7.5  → GPU_CC_INT=75
#
# cc >= 89  → Ada Lovelace (RTX 4090/4080/4070) / Hopper → cu124
# cc >= 80  → Ampere (RTX 3xxx / A100 / A6000)           → cu121
# cc < 80   → Turing / Volta / older                      → cu118

if [ "${GPU_CC_INT}" -ge 89 ]; then
    CUDA_INDEX="cu124"
elif [ "${GPU_CC_INT}" -ge 80 ]; then
    CUDA_INDEX="cu121"
else
    CUDA_INDEX="cu118"
fi

echo "=== Installing PyTorch for CUDA index: ${CUDA_INDEX} ==="
pip install --upgrade \
    torch torchvision torchaudio \
    --index-url "https://download.pytorch.org/whl/${CUDA_INDEX}"

echo ""
echo "=== Verifying installation ==="
python3 - <<'EOF'
import torch
print(f"PyTorch version : {torch.__version__}")
print(f"CUDA available  : {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version    : {torch.version.cuda}")
    print(f"GPU             : {torch.cuda.get_device_name(0)}")
    cc = torch.cuda.get_device_capability()
    print(f"Compute cap.    : {cc[0]}.{cc[1]}")
    # Quick kernel smoke-test
    t = torch.zeros(1).cuda()
    print("Kernel smoke-test: PASSED")
EOF

echo ""
echo "=== Done — restart Stable Diffusion WebUI now ==="
