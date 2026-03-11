# Video Composition — `ponyflash.editor`

Local video composition powered by FFmpeg. No cloud API needed.

```bash
pip install ponyflash[editor]
```

## Architecture

```
Asset → Clip → Track → Timeline → render()
```

- **Asset**: Raw content (file path or URL)
- **Clip**: Presentation layer (duration, fit, scale, position, opacity, volume, speed)
- **Track**: Timeline lane (`add_clip(start, clip)`)
- **Timeline**: Final canvas (aspect ratio, background) + render output

## Assets

### VideoAsset

```python
VideoAsset(source: str, *, start: float = 0.0, volume: float = 1.0)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `source` | `str` | required | Local file path or URL. URLs are auto-downloaded and cached |
| `start` | `float` | `0.0` | Trim start point in source file (seconds) |
| `volume` | `float` | `1.0` | Audio volume multiplier (`0.0` = silent, `1.0` = original) |

```python
v = VideoAsset("intro.mp4")
v = VideoAsset("clip.mp4", start=5.0, volume=0.8)
v = VideoAsset("https://example.com/video.mp4")  # auto-downloaded
```

### AudioAsset

```python
AudioAsset(source: str, *, start: float = 0.0, volume: float = 1.0)
```

Same parameters as `VideoAsset`. Used for background music, voiceover, sound effects.

```python
a = AudioAsset("bgm.mp3")
a = AudioAsset("voiceover.wav", start=2.0, volume=0.5)
```

### ImageAsset

```python
ImageAsset(source: str)
```

A still image. When used in a `Clip`, you must specify `duration`.

```python
img = ImageAsset("photo.jpg")
img = ImageAsset("https://example.com/cover.png")
```

### TextAsset

```python
TextAsset(
    text: str,
    *,
    font_size: int = 48,
    color: str = "white",
    font_file: str | None = None,
    box: bool = False,
    box_color: str = "black@0.5",
    box_border_w: int = 8,
    border_width: int = 0,
    border_color: str = "black",
    fade_in: float = 0.0,
    fade_out: float = 0.0,
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `text` | `str` | required | Text string to display |
| `font_size` | `int` | `48` | Font size in pixels |
| `color` | `str` | `"white"` | FFmpeg color name or hex (`"#ff0000"`) |
| `font_file` | `str \| None` | `None` | Path to `.ttf`/`.otf` font. `None` = FFmpeg default |
| `box` | `bool` | `False` | Draw background box behind text |
| `box_color` | `str` | `"black@0.5"` | Box fill with optional alpha |
| `box_border_w` | `int` | `8` | Padding inside box (px) |
| `border_width` | `int` | `0` | Text stroke width |
| `border_color` | `str` | `"black"` | Text stroke color |
| `fade_in` | `float` | `0.0` | Fade-in duration (seconds) |
| `fade_out` | `float` | `0.0` | Fade-out duration (seconds) |

```python
t = TextAsset("Hello World", font_size=60, color="white",
              box=True, box_color="black@0.5",
              border_width=2, border_color="black",
              fade_in=0.5, fade_out=0.5)
```

## Clip

```python
Clip(
    asset: Asset,
    *,
    duration: float | None = None,
    fit: Fit = Fit.COVER,
    position: Position | None = None,
    scale: float = 1.0,
    opacity: float = 1.0,
    volume: float = 1.0,
    crop_gravity: CropGravity = CropGravity.CENTER,
    speed: float = 1.0,
    transition: Transition | None = None,
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `asset` | Asset | required | The content to display |
| `duration` | `float \| None` | `None` | Clip length (seconds). Auto-detected for video; **required** for image/text |
| `fit` | `Fit` | `COVER` | Scaling mode |
| `position` | `Position \| None` | `None` | 9-zone anchor (for overlays/text) |
| `scale` | `float` | `1.0` | Size multiplier after fit (`0.3` = 30% of canvas) |
| `opacity` | `float` | `1.0` | Transparency (`0.0`–`1.0`) |
| `volume` | `float` | `1.0` | Audio volume multiplier |
| `crop_gravity` | `CropGravity` | `CENTER` | Which region to keep when COVER crops |
| `speed` | `float` | `1.0` | Playback speed (`2.0` = 2x fast) |
| `transition` | `Transition \| None` | `None` | Clip-level fade in/out |

**Methods:**

- `clip.mute()` — Mute audio. Returns `self` for chaining.

```python
clip = Clip(asset=VideoAsset("a.mp4"), duration=5.0, fit=Fit.COVER)
clip = Clip(asset=ImageAsset("photo.jpg"), duration=3.0, fit=Fit.CONTAIN)
clip = Clip(asset=VideoAsset("cam.mp4"), duration=10.0,
            position=Position.BOTTOM_RIGHT, scale=0.3)  # picture-in-picture
clip = Clip(asset=VideoAsset("slow.mp4"), duration=10.0, speed=0.5)  # slow motion
```

## Fit

| Value | Behavior | FFmpeg equivalent |
|---|---|---|
| `Fit.COVER` | Fill canvas, crop overflow | `scale + crop` |
| `Fit.CONTAIN` | Fit within canvas, show background | `scale + pad` |
| `Fit.FILL` | Stretch to fill (may distort) | `scale` |
<<<<<<< HEAD
| `Fit.NONE` | 保留原始像素尺寸，超出画布时裁切并居中 | `crop + pad` |

## CropGravity

Controls which region to keep when `Fit.COVER` crops:

`CENTER`, `TOP`, `BOTTOM`, `LEFT`, `RIGHT`

```python
Clip(asset=video, fit=Fit.COVER, crop_gravity=CropGravity.TOP)
```

## Position

9-zone anchor grid:

```
TOP_LEFT       TOP        TOP_RIGHT
CENTER_LEFT    CENTER     CENTER_RIGHT
BOTTOM_LEFT    BOTTOM     BOTTOM_RIGHT
```

## Track

```python
track = Track()
track.add_clip(start, clip, *, transition=None, transition_duration=None)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `start` | `float` | required | Absolute position on timeline (seconds) |
| `clip` | `Clip` | required | A Clip instance |
| `transition` | `XFade \| str \| None` | `None` | xfade transition to previous clip |
| `transition_duration` | `float \| None` | `None` | Cross-fade length (seconds). Defaults to `1.0` when transition is set |

The engine **automatically infers** each track's role from its clip types:

| Clip asset types | Inferred role | Processing |
|---|---|---|
| All `VideoAsset` / `ImageAsset` (first such track) | Main video | xfade chain |
| `VideoAsset` / `ImageAsset` with `position` or `scale != 1` | Overlay | `overlay` filter |
| All `TextAsset` | Text | `drawtext` filter |
| All `AudioAsset` | Audio | `adelay` + `amix` |

主视频轨时间线规则：

- `start` 是绝对时间线位置，不是“相对上一个 clip 的偏移”。
- 没有转场时允许 gap，渲染时会保留黑帧/静音。
- 没有转场时，主轨 clip 不能彼此重叠。
- 有转场时，后一个 clip 必须从前一个 clip 结束前 `transition_duration` 秒开始。
- 非法重叠会抛 `ClipOverlapError` 或 `ValidationError`。
```python
# Main video track with transitions
main = Track()
main.add_clip(0, clip1)
main.add_clip(4, clip2, transition=Transition.DISSOLVE, transition_duration=1.0)
main.add_clip(8.5, clip3, transition=Transition.WIPELEFT, transition_duration=0.5)

# Overlay track (picture-in-picture)
pip = Track()
pip.add_clip(3, Clip(asset=VideoAsset("cam.mp4"), duration=8,
                     position=Position.BOTTOM_RIGHT, scale=0.3))

# Text track
text = Track()
text.add_clip(1, Clip(asset=TextAsset("Title"), duration=3, position=Position.CENTER))

# Audio track
audio = Track()
audio.add_clip(0, Clip(asset=AudioAsset("bgm.mp3"), volume=0.3))
```

## Timeline

```python
timeline = Timeline(*, aspect_ratio: str | None = None, background: str = "#000000")
```

| Property | Type | Default | Description |
|---|---|---|---|
| `aspect_ratio` | `str \| None` | `None` | e.g. `"16:9"`, `"9:16"`, `"1:1"` |
| `background` | `str` | `"#000000"` | Background color (hex) |

**Methods:**

- `timeline.add_track(track)` — Append track. Order = z-order (later = on top).
- `timeline.render(output, *, resolution, format, fps, quality, progress)` — Render to file.

### render()

```python
timeline.render(
    output: str,
    *,
    resolution: str = "1080p",
    format: str | None = None,
    fps: int = 30,
    quality: str = "medium",
    progress: Callable[[float], None] | None = None,
) -> str
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `output` | `str` | required | Output file path |
| `resolution` | `str` | `"1080p"` | Preset or `"WxH"`（显式 `"WxH"` 需要偶数宽高） |
| `format` | `str \| None` | `None` | Output format (auto-detected from extension) |
| `fps` | `int` | `30` | Output frame rate |
| `quality` | `str` | `"medium"` | Quality preset |
| `progress` | callback | `None` | Called with current rendered time (seconds) |

**Resolution presets:**

| Preset | Landscape (16:9) | Portrait (9:16) | Square (1:1) |
|---|---|---|---|
| `"360p"` | 640x360 | 360x640 | 360x360 |
| `"480p"` | 854x480 | 480x854 | 480x480 |
| `"720p"` | 1280x720 | 720x1280 | 720x720 |
| `"1080p"` | 1920x1080 | 1080x1920 | 1080x1080 |
| `"2k"` | 2560x1440 | 1440x2560 | 1440x1440 |
| `"4k"` | 3840x2160 | 2160x3840 | 2160x2160 |

**Output formats:**

| Format key | Video codec | Audio codec | Extension |
|---|---|---|---|
| `"mp4"` | H.264 (libx264) | AAC | `.mp4` |
| `"mp4h265"` | H.265 (libx265) | AAC | `.mp4` |
| `"webm"` | VP9 (libvpx-vp9) | Opus | `.webm` |
| `"mov"` | ProRes | PCM | `.mov` |
| `"gif"` | GIF | none | `.gif` |

**Quality presets** (for H.264/H.265):

| Quality | Preset | CRF |
|---|---|---|
| `"low"` | ultrafast | 28 |
| `"medium"` | medium | 23 |
| `"high"` | slow | 18 |
| `"lossless"` | veryslow | 0 |

## Transitions

### Clip-level (fade in/out)

```python
from ponyflash.editor import Transition

clip = Clip(asset=video, duration=10,
            transition=Transition(in_="fade", out="fade", duration=2))
```

### Track-level (xfade between clips)

```python
track.add_clip(4, clip2, transition=Transition.DISSOLVE, transition_duration=1.0)
```

### All 58 xfade transition names

**Fade:** `FADE`, `FADEBLACK`, `FADEWHITE`, `FADEGRAYS`, `FADEFAST`, `FADESLOW`

**Wipe:** `WIPELEFT`, `WIPERIGHT`, `WIPEUP`, `WIPEDOWN`, `WIPETL`, `WIPETR`, `WIPEBL`, `WIPEBR`

**Slide:** `SLIDELEFT`, `SLIDERIGHT`, `SLIDEUP`, `SLIDEDOWN`

**Cover:** `COVERLEFT`, `COVERRIGHT`, `COVERUP`, `COVERDOWN`

**Reveal:** `REVEALLEFT`, `REVEALRIGHT`, `REVEALUP`, `REVEALDOWN`

**Circle:** `CIRCLEOPEN`, `CIRCLECLOSE`, `CIRCLECROP`

**Geometric:** `RECTCROP`, `VERTOPEN`, `VERTCLOSE`, `HORZOPEN`, `HORZCLOSE`, `DIAGTL`, `DIAGTR`, `DIAGBL`, `DIAGBR`

**Smooth:** `SMOOTHLEFT`, `SMOOTHRIGHT`, `SMOOTHUP`, `SMOOTHDOWN`

**Slice:** `HLSLICE`, `HRSLICE`, `VUSLICE`, `VDSLICE`

**Wind:** `HLWIND`, `HRWIND`, `VUWIND`, `VDWIND`

**Squeeze:** `SQUEEZEH`, `SQUEEZEV`

**Other:** `DISSOLVE`, `PIXELIZE`, `RADIAL`, `DISTANCE`, `HBLUR`, `ZOOMIN`

Usage: `Transition.DISSOLVE`, `Transition.WIPELEFT`, or string `"dissolve"`, `"wipeleft"`.

## AspectRatio presets

`LANDSCAPE_16_9`, `PORTRAIT_9_16`, `SQUARE_1_1`, `LANDSCAPE_4_3`, `PORTRAIT_3_4`, `ULTRAWIDE_21_9`

Or any string like `"16:9"`, `"21:9"`, `"3:2"`.

## Error handling

```python
from ponyflash.editor import (
    ComposeError,         # base class
    FFmpegNotFoundError,  # ffmpeg not installed
    FFprobeNotFoundError, # ffprobe not installed
    ProbeError,           # ffprobe failed on a file
    RenderError,          # ffmpeg render failed
    ClipOverlapError,     # clips overlap on same track
    ValidationError,      # invalid parameters
)
```
