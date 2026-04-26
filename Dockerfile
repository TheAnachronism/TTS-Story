FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/app/.cache/huggingface \
    TRANSFORMERS_CACHE=/app/.cache/huggingface/hub \
    TORCH_HOME=/app/.cache/torch \
    XDG_CACHE_HOME=/app/.cache \
    MPLCONFIGDIR=/app/.cache/matplotlib

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    espeak-ng \
    ffmpeg \
    gcc \
    g++ \
    git \
    libffi-dev \
    libglib2.0-0 \
    libsndfile1 \
    libsndfile1-dev \
    libsox-dev \
    libssl-dev \
    make \
    pkg-config \
    rubberband-cli \
    sox \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

RUN python -m pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
      "torch==2.6.0+cu124" \
      "torchvision==0.21.0+cu124" \
      "torchaudio==2.6.0+cu124" \
      --index-url https://download.pytorch.org/whl/cu124

RUN python - <<'PY'
from pathlib import Path

lines = []
for line in Path("requirements.txt").read_text(encoding="utf-8").splitlines():
    stripped = line.strip().lower()
    if stripped.startswith((
        "torch",
        "torchvision",
        "torchaudio",
        "pyopenjtalk",
    )):
        continue
    lines.append(line)

Path("/tmp/requirements.filtered.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

RUN pip install --no-cache-dir -r /tmp/requirements.filtered.txt && \
    (pip install --no-cache-dir chatterbox-tts || pip install --no-cache-dir chatterbox-tts --no-deps) && \
    (pip install --no-cache-dir pyopenjtalk || true)

COPY . .

RUN mkdir -p \
    /app/.cache/huggingface \
    /app/.cache/matplotlib \
    /app/data \
    /app/data/jobs \
    /app/data/voice_prompts \
    /app/models \
    /app/static/audio \
    /app/static/samples

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD curl -fsS http://127.0.0.1:5000/api/health || exit 1

CMD ["python", "app.py"]
