# Automatic1111 Stable Diffusion - Juggernaut XL

A RunPod serverless worker that runs [Automatic1111 Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) and exposes its `txt2img` API endpoint.

## 🎨 Pre-installed Models

- **[Juggernaut XL](https://huggingface.co/RunDiffusion/Juggernaut-XI-v11)** - Main SDXL model for image generation
- **[4x_NMKD-Siax_200k](https://huggingface.co/gemasai/4x_NMKD-Siax_200k)** - ESRGAN upscaler to enhance resolution

## 🚀 Usage

The `input` object accepts all valid parameters for Automatic1111's `/sdapi/v1/txt2img` endpoint. See the [Automatic1111 API Documentation](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API) for the complete list of available parameters (`seed`, `sampler_name`, `batch_size`, `styles`, `override_settings`, etc.).

### Request Example

Here's an example payload for generating an image:

```json
{
  "input": {
    "prompt": "a photograph of an astronaut riding a horse",
    "negative_prompt": "text, watermark, blurry, low quality",
    "steps": 6,
    "cfg_scale": 3,
    "width": 512,
    "height": 512,
    "sampler_name": "DPM++ SDE"
  }
}
```

### Example with Upscaling (Hires Fix)

The worker supports high-resolution upscaling with the pre-installed ESRGAN model:

```json
{
  "input": {
    "prompt": "a photograph of an astronaut riding a horse",
    "negative_prompt": "text, watermark, blurry, low quality",
    "steps": 6,
    "cfg_scale": 3,
    "width": 512,
    "height": 512,
    "sampler_name": "DPM++ SDE",
    "enable_hr": true,
    "hr_scale": 2,
    "hr_upscaler": "4x_NMKD-Siax_200k",
    "hr_second_pass_steps": 5,
    "denoising_strength": 0.25
  }
}
```

## 📋 Upscaling Parameters

- `enable_hr`: Enables Hires Fix (high-resolution upscaling)
- `hr_scale`: Upscaling factor (e.g., 2 to double the resolution)
- `hr_upscaler`: Name of the upscaler to use (`4x_NMKD-Siax_200k`)
- `hr_second_pass_steps`: Number of steps for the second pass
- `denoising_strength`: Denoising strength (0.0 to 1.0)

## 🛠️ Technical Configuration

- **A1111 Version**: v1.9.3
- **Base Image**: Python 3.10.14-slim
- **Optimizations**: 
  - xformers enabled
  - SDP attention
  - No half VAE for better quality
- **API Port**: 3000 (internal)

## 📦 Project Structure

```
.
├── Dockerfile              # Multi-stage Docker image
├── requirements.txt        # RunPod Python dependencies
├── test_input.json        # Test payload example
└── src/
    ├── handler.py         # RunPod serverless handler
    └── start.sh          # Startup script
```

## 🔧 Local Development

To test locally, you can use the provided `test_input.json` file which contains a complete example with upscaling.

## 📝 Notes

- Juggernaut XL model is optimized for high-quality generations
- ESRGAN upscaler significantly improves image resolution
- Recommended parameters are included in `test_input.json`
