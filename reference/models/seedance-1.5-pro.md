# seedance-1.5-pro — Video Generation (ByteDance)

Dual-branch diffusion transformer that generates audio and video simultaneously in a shared latent space. Ensures precise lip-sync and natural synchronized sound effects.

## Supported parameters via PonyFlash SDK

```python
gen = client.video.generate(
    model="seedance-1.5-pro",
    prompt="A dancer performing in the rain",
    duration=5,            # 2-12 seconds
)
```

## Key specifications

| Parameter | Values |
|---|---|
| Duration | 2–12 seconds (default 5) |
| Resolution | 720p |
| Frame rate | 24 FPS |
| Aspect ratio | 16:9 (default, ignored when using input image) |
| Audio | Auto-generated synchronized audio (enabled by default) |

## Supported languages

English, Mandarin Chinese, Japanese, Korean, Spanish, Portuguese, Indonesian dialects.

## Generation modes

| Mode | Required params | Description |
|---|---|---|
| Text-to-video | `prompt` | Generate video from text |
| Image-to-video | `first_frame` + `prompt` | Animate a starting image |
| First+last frame | `first_frame` + `last_frame` + `prompt` | Control start and end frames |

## Example: text-to-video

```python
gen = client.video.generate(
    model="seedance-1.5-pro",
    prompt="A cat playing piano, close-up, cinematic lighting",
    duration=8,
)
print(gen.url)
```

## Example: image-to-video

```python
with open("photo.jpg", "rb") as f:
    gen = client.video.generate(
        model="seedance-1.5-pro",
        first_frame=f,
        prompt="Camera slowly zooms in, leaves rustling in wind",
        duration=5,
    )
print(gen.url)
```

## Example: first + last frame

```python
with open("start.jpg", "rb") as s, open("end.jpg", "rb") as e:
    gen = client.video.generate(
        model="seedance-1.5-pro",
        first_frame=s,
        last_frame=e,
        prompt="Smooth transition between scenes",
        duration=5,
    )
```

## Notes

- Audio is generated simultaneously with video (lip-sync, sound effects).
- The `size` parameter is not used for this model; output is always 720p.
- Aspect ratio is 16:9 by default; ignored when an input image is provided (inherits image aspect ratio).
