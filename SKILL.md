---
name: ponyflash
description: >-
  Generate images, videos, speech audio, and music using the PonyFlash Python SDK.
  Use when the user asks to create, generate, or produce images, videos, speech,
  audio, music, or any AI-generated media content. Also use when checking PonyFlash
  account balance, listing models, or managing generated files.
---

# PonyFlash SDK

## Step 0: Install

Before doing anything, ensure the SDK is installed:

```bash
pip install ponyflash
```

Then set the API key via environment variable or pass it directly:

```bash
export PONYFLASH_API_KEY="pf_xxx"
```

## What this SDK can do

| Capability | Resource | Description |
|---|---|---|
| Image generation | `pony_flash.images` | Text-to-image, image editing with mask/reference images |
| Video generation | `pony_flash.video` | Text-to-video, first-frame-to-video, OmniHuman, Motion Transfer |
| Speech synthesis | `pony_flash.speech` | Text-to-speech with voice control, emotion, speed, pitch |
| Music generation | `pony_flash.music` | Text-to-music with lyrics, style, instrumental mode, continuation |
| Model listing | `pony_flash.models` | List available models, get model details and supported modes |
| File management | `pony_flash.files` | Upload, list, get, delete files |
| Account | `pony_flash.account` | Check credit balance, get recharge link |

## Core concepts

### Client initialization

```python
from ponyflash import PonyFlash

pony_flash = PonyFlash(api_key="pf_xxx")
```

Reads `PONYFLASH_API_KEY` from environment if `api_key` is omitted. 

### FileInput — zero-friction file handling

All file parameters accept any of these types:

| Input type | Example | Behavior |
|---|---|---|
| URL string | `"https://example.com/photo.jpg"` | Passed directly to API |
| file_id string | `"file_abc123"` | Passed directly to API |
| `Path` object | `Path("photo.jpg")` | Auto-uploaded via presigned URL |
| `open()` file | `open("photo.jpg", "rb")` | Auto-uploaded via presigned URL |
| `bytes` | `image_bytes` | Auto-uploaded via presigned URL |
| `(filename, bytes)` tuple | `("photo.jpg", data)` | Auto-uploaded with filename |

Temp uploads are cleaned up automatically after `generate()` completes.

### Generation result

`Generation` object fields: `request_id`, `status`, `outputs`, `usage`, `error`.

Convenience properties:
- `gen.url` — first output URL (or `None`)
- `gen.urls` — list of all output URLs
- `gen.credits` — credits consumed

## Quick examples (one per category)

### Image

```python
gen = pony_flash.images.generate(
    model="nano-banana-pro",
    prompt="A sunset over mountains",
    resolution="2K",
    aspect_ratio="16:9",
)
print(gen.url)
```

### Video

```python
gen = pony_flash.video.generate(
    model="seedance-1.5-pro",
    prompt="A timelapse of a city at night",
    duration=5,
)
print(gen.url)
```

### Speech

```python
gen = pony_flash.speech.generate(
    model="speech-2.8-hd",
    input="Hello, welcome to PonyFlash!",
    voice="English_Graceful_Lady",
)
print(gen.url)
```

### Music

```python
gen = pony_flash.music.generate(
    model="music-2.5",
    prompt="An upbeat electronic dance track",
    duration=30,
)
print(gen.url)
```

### List models

```python
page = pony_flash.models.list()
for model in page.items:
    print(f"{model.id} ({model.type})")
```

### Check balance

```python
balance = pony_flash.account.credits()
print(f"Balance: {balance.balance} {balance.currency}")
```

## Error handling

```python
from ponyflash import (
    PonyFlash,
    InsufficientCreditsError,
    RateLimitError,
    GenerationFailedError,
    AuthenticationError,
)

pony_flash = PonyFlash()

try:
    gen = pony_flash.images.generate(model="nanobanana-pro", prompt="A cat")
except AuthenticationError:
    print("Invalid API key")
except InsufficientCreditsError as e:
    print(f"Not enough credits. Balance: {e.balance}, required: {e.required}")
    link = pony_flash.account.recharge()
    print(f"Recharge at: {link.recharge_url}")
except RateLimitError:
    print("Rate limited — wait and retry")
except GenerationFailedError as e:
    print(f"Generation failed: {e.generation.error.code}")
```

## More examples

For advanced usage (image editing, OmniHuman, Motion Transfer, lyrics with structure tags, voice control, song continuation, etc.):
See [examples/advanced.md](examples/advanced.md)

## API reference (detailed signatures)

For complete method signatures, parameter types, and return type fields:

- **Image generation**: [reference/images.md](reference/images.md)
- **Video generation**: [reference/video.md](reference/video.md)
- **Speech synthesis**: [reference/speech.md](reference/speech.md)
- **Music generation**: [reference/music.md](reference/music.md)
- **Model listing**: [reference/models.md](reference/models.md)
- **File management**: [reference/files.md](reference/files.md)
- **Account / credits**: [reference/account.md](reference/account.md)

## Model catalog

For all available models and their specific parameters, capabilities, and examples:
See [reference/models/INDEX.md](reference/models/INDEX.md)
