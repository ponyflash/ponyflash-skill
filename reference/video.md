# Video API Reference

## Methods

### `client.video.submit(**kwargs) -> CreateResponse`

Submits a video generation request. Returns immediately.

### `client.video.generate(**kwargs) -> Generation`

Submits and polls until completion.

## Parameters

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `model` | `str` | Yes | — | Model ID (e.g. `"video-gen-1"`, `"omnihuman-1"`, `"motion-transfer-1"`) |
| `prompt` | `str` | No | — | Text description |
| `size` | `str` | No | — | Output size (e.g. `"1920x1080"`) |
| `duration` | `int` | No | — | Duration in seconds |
| `quality` | `str` | No | — | Quality level |
| `first_frame` | `FileInput` | No | — | Starting frame image |
| `last_frame` | `FileInput` | No | — | Ending frame image |
| `video` | `FileInput` | No | — | Input video |
| `audio` | `FileInput` | No | — | Audio track (for OmniHuman) |
| `reference_images` | `List[FileInput]` | No | — | Reference images |
| `motion_video` | `FileInput` | No | — | Motion source video (for Motion Transfer) |

`generate()` adds:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `poll_interval` | `float` | `5.0` | Seconds between status checks |
| `timeout` | `float` | `900.0` | Max seconds to wait (15 min) |

## Generation modes

| Mode | Required params | Model example |
|---|---|---|
| Text-to-video | `model`, `prompt` | `video-gen-1` |
| First-frame to video | `model`, `first_frame`, `prompt` | `video-gen-1` |
| OmniHuman | `model`, `first_frame`, `audio` | `omnihuman-1` |
| Motion Transfer | `model`, `first_frame`, `motion_video` | `motion-transfer-1` |

## Example

```python
gen = client.video.generate(
    model="video-gen-1",
    prompt="Ocean waves crashing on a beach",
    size="1920x1080",
    duration=8,
)
print(gen.url)
print(f"Credits: {gen.credits}")
```
