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
| Image generation | `client.images` | Text-to-image, image editing with mask/reference images |
| Video generation | `client.video` | Text-to-video, first-frame-to-video, OmniHuman (portrait+audio), Motion Transfer |
| Speech synthesis | `client.speech` | Text-to-speech with voice control, emotion, speed, pitch |
| Music generation | `client.music` | Text-to-music with lyrics, style, instrumental mode, continuation |
| Model listing | `client.models` | List available models, get model details and supported modes |
| File management | `client.files` | Upload, list, get, delete files |
| Generation polling | `client.generations` | Check status, wait for completion |
| Account | `client.account` | Check credit balance, get recharge link |

## Core concepts

### Client initialization

```python
from ponyflash import PonyFlash

client = PonyFlash(api_key="pf_xxx")
```

Reads `PONYFLASH_API_KEY` from environment if `api_key` is omitted. Base URL defaults to `https://api.ponyflash.com/v1`; override with `base_url` param or `PONYFLASH_BASE_URL` env var.



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

## Usage examples

### Text-to-image

```python
gen = client.images.generate(
    model="image-pro-1",
    prompt="A sunset over mountains",
    size="1024x1024",
)
print(gen.url)
print(f"Credits: {gen.credits}")
```

### Image editing with reference images

```python
from pathlib import Path

gen = client.images.generate(
    model="image-edit-1",
    prompt="Remove the background",
    images=[Path("photo.jpg")],
    mask=open("mask.png", "rb"),
)
print(gen.url)
```

### Multiple images

```python
gen = client.images.generate(
    model="image-pro-1",
    prompt="A cat in space",
    n=4,
    size="512x512",
)
for url in gen.urls:
    print(url)
```

### Text-to-video

```python
gen = client.video.generate(
    model="video-gen-1",
    prompt="A timelapse of a city at night",
    size="1920x1080",
    duration=8,
)
print(gen.url)
```

### First-frame to video (local file)

```python
with open("my_photo.jpg", "rb") as f:
    gen = client.video.generate(
        model="video-gen-1",
        first_frame=f,
        prompt="Camera slowly zooms in",
    )
```

### First-frame to video (URL)

```python
gen = client.video.generate(
    model="video-gen-1",
    first_frame="https://example.com/photo.jpg",
    prompt="Camera slowly zooms in",
)
```

### OmniHuman — portrait + audio to talking video

```python
with open("portrait.jpg", "rb") as img, open("speech.wav", "rb") as audio:
    gen = client.video.generate(
        model="omnihuman-1",
        first_frame=img,
        audio=audio,
        size="1280x720",
    )
```

### Motion Transfer — person image + dance video

```python
with open("avatar.jpg", "rb") as img, open("dance.mp4", "rb") as vid:
    gen = client.video.generate(
        model="motion-transfer-1",
        first_frame=img,
        motion_video=vid,
        size="1280x720",
    )
```

### Text-to-speech

```python
gen = client.speech.generate(
    model="speech-v1",
    input="Hello, welcome to PonyFlash!",
    voice="alloy",
)
print(gen.url)
```

### Speech with full voice control

```python
gen = client.speech.generate(
    model="speech-v1",
    input="Breaking news: AI can now compose music.",
    voice="nova",
    language="en",
    speed=1.2,
    pitch=2,
    emotion="excited",
    instructions="Speak like a news anchor",
    voice_settings={
        "stability": 0.8,
        "similarity_boost": 0.9,
        "style": 0.5,
        "use_speaker_boost": True,
    },
    sample_rate=44100,
    format="mp3",
)
```

### Music generation

```python
gen = client.music.generate(
    model="music-gen-1",
    prompt="An upbeat electronic dance track",
    duration=30,
)
print(gen.url)
```

### Music with lyrics and style

```python
gen = client.music.generate(
    model="music-gen-1",
    prompt="A romantic ballad about the ocean",
    lyrics="Waves crash upon the shore\nWhispering forevermore",
    title="Ocean Whispers",
    style="pop ballad",
    duration=60,
)
```

### Instrumental music

```python
gen = client.music.generate(
    model="music-gen-1",
    prompt="Lo-fi hip hop study beats",
    instrumental=True,
    duration=120,
)
```

### Continue / extend a song

```python
gen = client.music.generate(
    model="music-gen-1",
    prompt="Continue with a guitar solo",
    reference_audio=open("my_song.mp3", "rb"),
    continue_at=45.0,
)
```

### List available models

```python
page = client.models.list()
for model in page.items:
    print(f"{model.id} ({model.type})")

page = client.models.list(type="image")
```

### Get model details

```python
detail = client.models.get("image-pro-1")
print(detail.supported_sizes)
print(detail.supported_modes)
```

### Check credit balance

```python
balance = client.account.credits()
print(f"Balance: {balance.balance} {balance.currency}")
```

### Get recharge link

```python
resp = client.account.recharge(amount=100)
print(resp.recharge_url)
```

### Async example — parallel generation

```python
import asyncio
from ponyflash import AsyncPonyFlash

async def main():
    client = AsyncPonyFlash()

    img, vid = await asyncio.gather(
        client.images.generate(model="image-pro-1", prompt="A cat"),
        client.video.generate(model="video-gen-1", prompt="A flying cat", duration=5),
    )
    print(f"Image: {img.url}")
    print(f"Video: {vid.url}")

asyncio.run(main())
```

## API reference (detailed signatures)

For complete method signatures, parameter types, and return type fields, see:

- **Image generation**: See [reference/images.md](reference/images.md)
- **Video generation**: See [reference/video.md](reference/video.md)
- **Speech synthesis**: See [reference/speech.md](reference/speech.md)
- **Music generation**: See [reference/music.md](reference/music.md)
- **Model listing**: See [reference/models.md](reference/models.md)
- **File management**: See [reference/files.md](reference/files.md)
- **Generation polling**: See [reference/generations.md](reference/generations.md)
- **Account / credits**: See [reference/account.md](reference/account.md)
