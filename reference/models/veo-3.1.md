# veo-3.1 — Video Generation (Google)

Google's high-quality video generation model. Supports text-to-video, image-to-video, first+last frame, video extension, and reference image guidance.

## Supported parameters via PonyFlash SDK

```python
gen = pony_flash.video.generate(
    model="veo-3.1",
    prompt="Ocean waves crashing on a rocky coastline at sunset",
    size="1920x1080",     # 720p or 1080p
    duration=8,           # 4, 6, or 8 seconds
)
```

## Key specifications

| Parameter | Values |
|---|---|
| Resolution | 720p, 1080p |
| Duration | 4, 6, or 8 seconds |
| Frame rate | 24 FPS |
| Aspect ratios | 16:9 (landscape), 9:16 (portrait) |
| Output format | MP4 (video/mp4) |
| Max outputs per request | 4 videos |
| Max image input size | 20 MB |
| Language | English only |

## Generation modes

| Mode | Required params | Notes |
|---|---|---|
| Text-to-video | `prompt` | All durations supported |
| Image-to-video | `first_frame` + `prompt` | Reference-image-to-video supports 8s only |
| First+last frame | `first_frame` + `last_frame` + `prompt` | |
| Video extension | `video` + `prompt` | Extend an existing video |
| Reference images | `reference_images` + `prompt` | Up to 3 asset images or 1 style image |

## Example: text-to-video (1080p)

```python
gen = pony_flash.video.generate(
    model="veo-3.1",
    prompt="A drone shot flying over a misty mountain forest at sunrise",
    size="1920x1080",
    duration=8,
)
print(gen.url)
```

## Example: image-to-video

```python
gen = pony_flash.video.generate(
    model="veo-3.1",
    first_frame="https://example.com/landscape.jpg",
    prompt="Camera slowly pans right revealing a waterfall",
    size="1920x1080",
    duration=8,
)
```

## Example: with reference images

```python
from pathlib import Path

gen = pony_flash.video.generate(
    model="veo-3.1",
    prompt="A person walking through a garden",
    reference_images=[Path("style_ref.jpg")],
    size="1280x720",
    duration=6,
)
```

## Notes

- Prompt language: English only.
- Duration 8s is the only option when using reference-image-to-video.
- 1080p output produces higher quality but takes longer to generate.
