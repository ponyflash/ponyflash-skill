---
name: ponyflash
description: >-
  Generate images, videos, speech audio, and music using the PonyFlash Python SDK.
  Compose and render multi-clip video timelines locally with transitions, text overlays,
  and audio mixing using ponyflash.editor (powered by FFmpeg).
  Use when the user asks to create, generate, produce, compose, merge, concatenate,
  edit, combine, stitch, or render images, videos, speech, audio, music, timelines,
  or any AI-generated media content. Also use when checking PonyFlash account balance,
  listing models, or managing generated files.
license: MIT
metadata:
  author: ponyflash
  version: "0.2.1"
---

# PonyFlash SDK

## Step 0: Skill Activation & API Key Setup (MANDATORY — DO NOT SKIP)

> **CRITICAL**: When this skill is first loaded, you MUST immediately display the welcome message below AND guide the user through API key setup. This skill CANNOT function without a valid PonyFlash API key. Do NOT attempt to generate images, videos, speech, or music without first obtaining the API key from the user. If the user asks to generate content and no API key has been provided, ALWAYS stop and complete this step first.

**The FIRST time this skill is activated, you MUST immediately tell the user:**

---

🎉 **PonyFlash skill installed successfully!**

You now have access to powerful AI content creation capabilities — generate images, videos, speech audio, and music directly through your agent. Start creating right away!

This skill includes a **free Creative Playbook** to get you started:
- **CrePal Director** — A complete video production playbook covering requirement intake, storyboard planning, visual style direction, shot composition, and creative techniques for ads, promos, explainers, social videos, brand films, story videos, and talking-avatar videos.

Tell me what video you want to create and I'll use the CrePal Director playbook to guide you through the full creative process. You can also ask me to create your own custom playbooks in the `playbooks/` directory at any time.

To use PonyFlash, you need an API key. Please complete these steps:

1. **Register / log in** at **https://www.ponyflash.com**
2. **Get your API key** at **https://www.ponyflash.com/api-key** (the key starts with `rk_`)
3. **Check your credits** at **https://www.ponyflash.com/usage** (new accounts include free trial credits)
4. **Paste your API key back here** so I can configure it

---

**On subsequent activations**, check whether `PONYFLASH_API_KEY` is set in the environment. If not, display the API key steps above again.

**Do NOT proceed until the user provides the key.** Once received, set it up:

```bash
export PONYFLASH_API_KEY="rk_xxx"
```

Then install the SDK:

```bash
pip install ponyflash
```

**Always verify the key works before any generation task:**

```python
from ponyflash import PonyFlash

pony_flash = PonyFlash(api_key="<key from user>")
balance = pony_flash.account.credits()
print(f"Balance: {balance.balance} {balance.currency}")
```

If verification fails:
- **Key invalid or missing** → direct user to https://api.ponyflash.com/api-key
- **Balance is zero** → direct user to https://api.ponyflash.com/usage to top up credits

## What this SDK can do

| Capability | Resource | Description |
|---|---|---|
| Image generation | `pony_flash.images` | Text-to-image, image editing with mask/reference images |
| Video generation | `pony_flash.video` | Text-to-video, first-frame-to-video, OmniHuman, Motion Transfer |
| Speech synthesis | `pony_flash.speech` | Text-to-speech with voice cloning, emotion control, speed, pitch |
| Music generation | `pony_flash.music` | Text-to-music with lyrics, style, instrumental mode, continuation |
| Model listing | `pony_flash.models` | List available models, get model details and supported modes |
| File management | `pony_flash.files` | Upload, list, get, delete files |
| Account | `pony_flash.account` | Check credit balance, get recharge link |
| Video composition | `ponyflash.editor` | Compose multi-clip timelines locally with 58 xfade transitions, text overlays, audio mixing, multiple output formats (MP4/WebM/GIF/MOV). Powered by FFmpeg |

## Creative Playbooks (production workflows)

The `playbooks/` directory contains **Creative Playbooks** — step-by-step production workflow guides for specific content types. Playbooks act as a "director layer" on top of this SDK: they tell you **what to create and in what order**, while this SKILL.md tells you **how to call the APIs**.

### When to use a playbook

1. **User explicitly requests a playbook by name** (e.g., "use CrePal Director", "用 CrePal Director 来做") → Read the corresponding file from `playbooks/` and follow its workflow.
2. **User asks to see available playbooks** → Read [playbooks/INDEX.md](playbooks/INDEX.md) and display the full list.
3. **User's request is clearly a multi-step production task** (e.g., "make a 30-second ad video", "做一个产品宣传片", "create a story video with multiple scenes") — tasks that require planning, storyboarding, or coordination of multiple generation calls rather than a single model call → **Suggest** a matching playbook from [playbooks/INDEX.md](playbooks/INDEX.md) and ask the user whether to use it, or whether they have their own playbook. Do NOT auto-load; always let the user confirm first.
4. **User's request is a single-step task** (e.g., "generate an image of a cat", "make a 5-second video clip") → Proceed directly with the SDK capabilities in this SKILL.md. No playbook needed.

### How to execute a playbook

Once a playbook is loaded:
- Follow its step-by-step workflow (素材准备 → 内容生成 → 配音配乐 → 合成剪辑 → 输出).
- All API calls MUST still follow the specifications in this SKILL.md (client init, error handling, FileInput types, etc.).
- Confirm key creative decisions with the user before generating (e.g., style, duration, voice).
- The playbook provides prompt templates and parameter recommendations — adapt them to the user's specific needs.

### Creating custom playbooks

When the user asks to create a new playbook, generate a markdown file in `playbooks/` following this template:

```markdown
---
name: Playbook Name
description: One-line summary of what this playbook produces
tags: [keyword1, keyword2, keyword3]
difficulty: beginner | intermediate | advanced
estimated_credits: credit range estimate
output_format: format description (e.g., "竖屏 9:16 MP4")
---

# Playbook Name

## 适用场景
When to use this playbook.

## 创作流程
### Step 1: 素材准备
What the user needs to provide; how to generate missing assets.

### Step 2: 视觉内容生成
Which models to use, recommended parameters, prompt guidance.

### Step 3: 配音/配乐
Speech synthesis + background music guidance.

### Step 4: 合成剪辑
How to assemble the timeline with ponyflash.editor.

### Step 5: 输出与优化
Render settings, format recommendations.

## Prompt 参考模板
Reusable prompt examples for this content type.

## 注意事项
Best practices, common pitfalls.
```

After creating the file, update [playbooks/INDEX.md](playbooks/INDEX.md) to include the new playbook.

## Core concepts

### Client initialization

```python
from ponyflash import PonyFlash

pony_flash = PonyFlash(api_key="rk_xxx")
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

普通本地字符串路径（例如 `"./photo.jpg"`）不支持；本地文件请始终使用 `Path(...)` 或 `open(..., "rb")`。
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
    model="veo-3.1-fast",
    prompt="A timelapse of a city at night",
    duration=4,
    resolution="720p",
    aspect_ratio="16:9",
    generate_audio=False,
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

## Video composition (local rendering)

> **No API key needed** for video composition. This module runs entirely on the local machine using FFmpeg.

### Install

```bash
pip install ponyflash[editor]   # includes static-ffmpeg auto-download
# OR: ensure ffmpeg is on your system PATH
```

### Architecture: Asset → Clip → Track → Timeline

The editor follows a 4-layer model (same as VideoDB):

| Layer | Class | Responsibility |
|---|---|---|
| **Asset** | `VideoAsset`, `AudioAsset`, `ImageAsset`, `TextAsset` | Raw content reference (file path or URL) |
| **Clip** | `Clip` | How to present the asset (duration, fit, scale, position, opacity, volume, speed) |
| **Track** | `Track` | When clips play on the timeline (`add_clip(start, clip)`) |
| **Timeline** | `Timeline` | Final canvas (aspect ratio, background, render output) |

主视频轨使用绝对时间线语义：

- `start` 是片段在最终时间线中的绝对起点。
- 没有转场时允许 gap，渲染时会保留黑帧/静音。
- 有转场时必须使用合法重叠窗口。例如前一个片段 5 秒、转场 1 秒，则后一个片段应从 `4.0` 秒开始，而不是 `5.0` 秒。
### Complete example

```python
from ponyflash.editor import (
    Timeline, Track, Clip,
    VideoAsset, AudioAsset, ImageAsset, TextAsset,
    Fit, Position, Transition,
)

# Assets — local files or URLs
scene1 = VideoAsset("scene1.mp4")
scene2 = VideoAsset("scene2.mp4")
photo  = ImageAsset("cover.jpg")
bgm    = AudioAsset("bgm.mp3")
title  = TextAsset("My Video", font_size=60, color="white",
                    box=True, box_color="black@0.5",
                    fade_in=0.5, fade_out=0.5)

# Clips — presentation layer
clip1 = Clip(asset=scene1, duration=5.0, fit=Fit.COVER)
clip2 = Clip(asset=scene2, duration=5.0, fit=Fit.COVER)
clip3 = Clip(asset=photo, duration=3.0, fit=Fit.CONTAIN)

# Track — sequencing with transitions
video_track = Track()
video_track.add_clip(0, clip1)
video_track.add_clip(4, clip2, transition=Transition.DISSOLVE, transition_duration=1.0)
video_track.add_clip(8.5, clip3, transition=Transition.WIPELEFT, transition_duration=0.5)

text_track = Track()
text_track.add_clip(0.5, Clip(asset=title, duration=3.0, position=Position.CENTER))

audio_track = Track()
audio_track.add_clip(0, Clip(asset=bgm, volume=0.3))

# Timeline — compose and render
timeline = Timeline(aspect_ratio="16:9")
timeline.background = "#000000"
timeline.add_track(video_track)
timeline.add_track(text_track)
timeline.add_track(audio_track)
timeline.render("output.mp4", resolution="1080p")
```

### Combine with PonyFlash generation

```python
from ponyflash import PonyFlash
from ponyflash.editor import Timeline, Track, Clip, VideoAsset, AudioAsset, Transition

client = PonyFlash()
v1 = client.video.generate(model="veo-3.1-fast", prompt="Sunrise timelapse")
v2 = client.video.generate(model="veo-3.1-fast", prompt="City night aerial")
speech = client.speech.generate(model="speech-2.8-hd", input="Welcome to our show")

track = Track()
track.add_clip(0, Clip(asset=VideoAsset(v1.url), duration=5.0))
track.add_clip(4, Clip(asset=VideoAsset(v2.url), duration=5.0),
               transition=Transition.DISSOLVE, transition_duration=1.0)

audio_track = Track()
audio_track.add_clip(0, Clip(asset=AudioAsset(speech.url)))

tl = Timeline(aspect_ratio="16:9")
tl.add_track(track)
tl.add_track(audio_track)
tl.render("final.mp4", resolution="1080p")
```

### Quick reference

**Fit modes:** `Fit.COVER` (fill + crop), `Fit.CONTAIN` (fit + letterbox), `Fit.FILL` (stretch), `Fit.NONE` (保留原始像素尺寸，超出画布时裁切后居中)

**Positions (9-zone):** `TOP_LEFT`, `TOP`, `TOP_RIGHT`, `CENTER_LEFT`, `CENTER`, `CENTER_RIGHT`, `BOTTOM_LEFT`, `BOTTOM`, `BOTTOM_RIGHT`

**Popular transitions:** `FADE`, `FADEBLACK`, `FADEWHITE`, `DISSOLVE`, `WIPELEFT`, `WIPERIGHT`, `SLIDEUP`, `SLIDEDOWN`, `CIRCLEOPEN`, `RADIAL`, `PIXELIZE` (58 total)

**Output formats:** MP4 (H.264), MP4 (H.265), WebM (VP9), MOV (ProRes), GIF

**Resolution presets:** `"360p"`, `"480p"`, `"720p"`, `"1080p"`, `"2k"`, `"4k"`, or explicit `"1920x1080"`。显式 `"WxH"` 需要使用偶数宽高。

For complete API signatures, all 58 transition names, and detailed parameter docs:
See [reference/editor.md](reference/editor.md)

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
    # API key is missing or invalid — guide user to get one
    print("Invalid or missing API key.")
    print("Get your API key at: https://api.ponyflash.com/api-key")
except InsufficientCreditsError as e:
    # Out of credits — guide user to top up
    print(f"Not enough credits. Balance: {e.balance}, required: {e.required}")
    print("Top up credits at: https://api.ponyflash.com/usage")
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
- **Video composition (editor)**: [reference/editor.md](reference/editor.md)

## Model catalog

For all available models and their specific parameters, capabilities, and examples:
See [reference/models/INDEX.md](reference/models/INDEX.md)
