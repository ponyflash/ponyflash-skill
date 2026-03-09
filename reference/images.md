# Images API Reference

## Methods

### `client.images.submit(**kwargs) -> CreateResponse`

Submits an image generation request. Returns immediately with `request_id`.

### `client.images.generate(**kwargs) -> Generation`

Submits and polls until completion. Returns `Generation` with output URLs.

## Parameters

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `model` | `str` | Yes | — | Model ID (e.g. `"nanobanana-pro"`, `"nanobanana"`) |
| `prompt` | `str` | Yes | — | Text description of the image to generate |
| `size` | `str` | No | — | Output size (e.g. `"1024x1024"`, `"512x512"`) |
| `n` | `int` | No | — | Number of images to generate |
| `quality` | `str` | No | — | Quality level |
| `output_format` | `str` | No | — | Output format |
| `images` | `List[FileInput]` | No | — | Reference/input images for editing |
| `mask` | `FileInput` | No | — | Mask image for inpainting |
| `context` | `str` | No | — | Additional context for the generation |

`generate()` adds:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `poll_interval` | `float` | `2.0` | Seconds between status checks |
| `timeout` | `float` | `120.0` | Max seconds to wait |

## Return types

### CreateResponse

| Field | Type | Description |
|---|---|---|
| `request_id` | `str` | Unique generation request ID |
| `estimated_credits` | `int \| None` | Estimated credit cost |

### Generation

| Field | Type | Description |
|---|---|---|
| `request_id` | `str` | Request ID |
| `status` | `"queued" \| "running" \| "succeeded" \| "failed"` | Current status |
| `outputs` | `List[GenerationOutput]` | Output items |
| `usage` | `GenerationUsage \| None` | Credit usage |
| `error` | `GenerationError \| None` | Error details if failed |

**Convenience properties:** `gen.url` (first URL), `gen.urls` (all URLs), `gen.credits` (credits used).

### GenerationOutput

| Field | Type |
|---|---|
| `url` | `str \| None` |
| `duration_sec` | `float \| None` |

## Example

```python
gen = client.images.generate(
    model="nanobanana-pro",
    prompt="A cyberpunk cityscape at night",
    size="2K",
    n=2,
)
for url in gen.urls:
    print(url)
```

## Available models

- [nanobanana-pro / nanobanana](models/nanobanana-pro.md) — sizes (1K/2K/4K), aspect ratios, credit costs, image-to-image

For the full model list, see [models/INDEX.md](models/INDEX.md).
