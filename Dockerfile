# trigger rebuild
# ---------------------------------------------------------------------------- #
#                        Build the final image                                 #
# ---------------------------------------------------------------------------- #
FROM python:3.10.14-slim

ARG A1111_RELEASE=v1.9.3

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    ROOT=/stable-diffusion-webui \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt install -y \
    fonts-dejavu-core rsync git jq moreutils aria2 wget libgoogle-perftools-dev libtcmalloc-minimal4 procps libgl1 libglib2.0-0 && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && apt-get clean -y

# Clone the repository
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd stable-diffusion-webui && \
    git reset --hard ${A1111_RELEASE}

# Install xformers separately to reduce memory pressure
# RUN --mount=type=cache,target=/root/.cache/pip \
#     pip install --no-cache-dir xformers

# Install requirements_versions.txt with memory optimization
RUN --mount=type=cache,target=/root/.cache/pip \
    cd stable-diffusion-webui && \
    pip install --no-cache-dir -r requirements_versions.txt

# Prepare environment
# RUN cd stable-diffusion-webui && \
  #  python -c "from launch import prepare_environment; prepare_environment()" --skip-torch-cuda-test

# Install CUDA-compatible PyTorch first
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir \
    torch==2.3.1+cu121 \
    torchvision==0.18.1+cu121 \
    --index-url https://download.pytorch.org/whl/cu121

# Manually install A1111 required repositories
RUN mkdir -p /stable-diffusion-webui/repositories

RUN rm -rf /stable-diffusion-webui/repositories/stable-diffusion-stability-ai && \
    git clone --depth 1 https://github.com/w-e-w/stablediffusion.git \
    /stable-diffusion-webui/repositories/stable-diffusion-stability-ai

RUN rm -rf /stable-diffusion-webui/repositories/generative-models && \
    git clone https://github.com/Stability-AI/generative-models.git \
    /stable-diffusion-webui/repositories/generative-models && \
    git -C /stable-diffusion-webui/repositories/generative-models \
    checkout 45c443b316737a4ab6e40413d7794a7f5657c19f

RUN rm -rf /stable-diffusion-webui/repositories/k-diffusion && \
    git clone --depth 1 https://github.com/crowsonkb/k-diffusion.git \
    /stable-diffusion-webui/repositories/k-diffusion

RUN rm -rf /stable-diffusion-webui/repositories/CodeFormer && \
    git clone --depth 1 https://github.com/sczhou/CodeFormer.git \
    /stable-diffusion-webui/repositories/CodeFormer

RUN rm -rf /stable-diffusion-webui/repositories/BLIP && \
    git clone --depth 1 https://github.com/salesforce/BLIP.git \
    /stable-diffusion-webui/repositories/BLIP

# Download models directly in the final image (no duplication!)
RUN --mount=type=secret,id=HF_TOKEN \
    mkdir -p /stable-diffusion-webui/models/Stable-diffusion && \
    mkdir -p /stable-diffusion-webui/models/ESRGAN && \
    echo "Downloading models..." && \
    HF_TOKEN_VALUE=$(cat /run/secrets/HF_TOKEN 2>/dev/null || echo "") && \
    if [ -z "$HF_TOKEN_VALUE" ]; then \
        echo "Warning: HF_TOKEN not provided, attempting download without auth..."; \
        wget --no-check-certificate -q -O /stable-diffusion-webui/models/Stable-diffusion/JuggernautXL.safetensors https://huggingface.co/RunDiffusion/Juggernaut-XI-v11/resolve/main/Juggernaut-XI-byRunDiffusion.safetensors || exit 1; \
        wget --no-check-certificate -q -O /stable-diffusion-webui/models/ESRGAN/4x_NMKD-Siax_200k.pth https://huggingface.co/gemasai/4x_NMKD-Siax_200k/resolve/main/4x_NMKD-Siax_200k.pth || exit 1; \
    else \
        wget --header="Authorization: Bearer $HF_TOKEN_VALUE" -q -O /stable-diffusion-webui/models/Stable-diffusion/JuggernautXL.safetensors https://huggingface.co/RunDiffusion/Juggernaut-XI-v11/resolve/main/Juggernaut-XI-byRunDiffusion.safetensors || exit 1; \
        wget --header="Authorization: Bearer $HF_TOKEN_VALUE" -q -O /stable-diffusion-webui/models/ESRGAN/4x_NMKD-Siax_200k.pth https://huggingface.co/gemasai/4x_NMKD-Siax_200k/resolve/main/4x_NMKD-Siax_200k.pth || exit 1; \
    fi && \
    echo "Verifying downloads..." && \
    test -f /stable-diffusion-webui/models/Stable-diffusion/JuggernautXL.safetensors || (echo "ERROR: JuggernautXL.safetensors not found" && exit 1) && \
    test -f /stable-diffusion-webui/models/ESRGAN/4x_NMKD-Siax_200k.pth || (echo "ERROR: 4x_NMKD-Siax_200k.pth not found" && exit 1) && \
    ls -lh /stable-diffusion-webui/models/Stable-diffusion/ && \
    ls -lh /stable-diffusion-webui/models/ESRGAN/ && \
    echo "Download successful!"

# install dependencies
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

COPY test_input.json .

ADD src .

RUN chmod +x /start.sh
CMD /start.sh
