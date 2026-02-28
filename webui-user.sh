#!/usr/bin/env bash
# webui-user.sh — AUTOMATIC1111 / Stable Diffusion WebUI launch configuration
#
# Place this file in the root of your stable-diffusion-webui directory (or symlink it).
# It is sourced by webui.sh before launching the UI.
#
# Fixes addressed here:
#   • RuntimeError: CUDA error: no kernel image is available for execution on the device
#     → caused by PyTorch/CUDA architecture mismatch (run fix_cuda.sh first, then use
#       the flags below as a safe fallback).

# ── Python executable ────────────────────────────────────────────────────────
# Uncomment and set if you use a non-default venv path.
# export python_cmd="python3"
# export venv_dir="venv"

# ── Extra launch arguments ────────────────────────────────────────────────────
# Explanation of flags relevant to the CUDA kernel error:
#
#   --no-half
#       Run the model in full float32 precision.  Eliminates most fp16 kernel
#       issues on GPUs that technically support CUDA but whose fp16 kernels are
#       not bundled in the installed PyTorch wheel.  Increases VRAM usage.
#
#   --no-half-vae
#       Keep the VAE in float32 only.  Prevents the black-image / NaN artifact
#       that commonly accompanies the "no kernel image" error on newer GPUs.
#
#   --precision full
#       Force full float32 throughout.  Use together with --no-half when the
#       above flags alone are not enough.
#
#   --medvram / --lowvram
#       Reduce peak VRAM usage.  Not directly related to the CUDA error, but
#       helpful if you are also hitting OOM errors on the same pod.
#
# Start with the minimal set below.  If the error persists after running
# fix_cuda.sh, uncomment --no-half and --precision full as a fallback.

export COMMANDLINE_ARGS="--no-half-vae --medvram"

# Uncomment the line below as a last resort if fix_cuda.sh does not help:
# export COMMANDLINE_ARGS="--no-half --no-half-vae --precision full --medvram"

# ── Git ───────────────────────────────────────────────────────────────────────
# Prevent the WebUI from auto-updating itself (useful on a shared RunPod pod).
# export GIT="git"

# ── Torch command ─────────────────────────────────────────────────────────────
# Override the torch install command if you need a specific CUDA wheel.
# Example for CUDA 12.4 (RTX 4090 / 4080 / 4070, compute cap ≥ 8.9):
# export torch_command="pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124"
#
# Example for CUDA 12.1 (RTX 3xxx / Ampere):
# export torch_command="pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121"
#
# Example for CUDA 11.8 (older GPUs):
# export torch_command="pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118"
