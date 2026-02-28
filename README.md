# _wolverine

Stable Diffusion WebUI workspace on RunPod.

---

## Fix: `RuntimeError: CUDA error: no kernel image is available for execution on the device`

This error means the installed PyTorch was compiled for a **different GPU architecture**
than the one on your RunPod pod (e.g. an RTX 4090 / Ada Lovelace GPU needs `cu121` or
`cu124`, but an older PyTorch wheel only contains kernels for `cu118` / Ampere and below).

### Step 1 — Run the auto-fix script (recommended)

Open a terminal on your RunPod pod and run:

```bash
bash fix_cuda.sh
```

The script will:
1. Detect your GPU's compute capability via `torch` / `nvidia-smi`.
2. Pick the correct CUDA wheel index (`cu118`, `cu121`, or `cu124`).
3. Reinstall `torch`, `torchvision`, and `torchaudio` from the matching wheel.
4. Run a quick kernel smoke-test to confirm the fix worked.
5. Print **"Done — restart Stable Diffusion WebUI now"** on success.

Then restart the WebUI.

---

### Step 2 — Apply safe launch flags (fallback)

If the error still appears after Step 1, copy `webui-user.sh` into the root of your
`stable-diffusion-webui` directory and restart:

```bash
cp webui-user.sh /workspace/stable-diffusion-webui/webui-user.sh
```

The default flags in that file are:

```
--no-half-vae --medvram
```

If the issue persists, edit `webui-user.sh` and switch to the full fallback line:

```bash
export COMMANDLINE_ARGS="--no-half --no-half-vae --precision full --medvram"
```

> **Note:** `--no-half` runs the model in float32, which uses more VRAM but eliminates
> virtually all fp16 kernel-mismatch errors.

---

### Quick reference — compute capability → CUDA wheel

| GPU family | Examples | Compute cap. | Wheel |
|---|---|---|---|
| Ada Lovelace | RTX 4090, 4080, 4070 (cc ≥ 8.9) | `8.9` | `cu124` |
| Hopper | H100 | `9.0` | `cu124` |
| Ampere / Ada (lower) | RTX 3xxx, A100, A6000, RTX 4060 (cc 8.0–8.6) | `8.0–8.6` | `cu121` |
| Turing / Volta | RTX 2080, V100 | `7.0–7.5` | `cu118` |

To check your GPU's compute capability:

```bash
python3 -c "import torch; print(torch.cuda.get_device_capability())"
```

---

## Files

| File | Purpose |
|---|---|
| `fix_cuda.sh` | Auto-detects GPU and reinstalls the correct PyTorch wheel |
| `webui-user.sh` | AUTOMATIC1111 launch config with safe fallback flags |
