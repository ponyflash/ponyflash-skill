# Generations API Reference

## Methods

### `client.generations.get(request_id: str) -> Generation`

Get the current status of a generation request.

### `client.generations.wait(request_id, *, poll_interval=2.0, timeout=600.0) -> Generation`

Poll until the generation completes or fails.

Raises `GenerationFailedError` if the task fails, `GenerationTimeoutError` if polling exceeds `timeout`.

## Parameters

### wait()

| Parameter | Type | Default | Description |
|---|---|---|---|
| `request_id` | `str` | — | The request ID from `submit()` |
| `poll_interval` | `float` | `2.0` | Initial seconds between polls (auto-increases with backoff, max 10s) |
| `timeout` | `float` | `600.0` | Max seconds to wait |

## Return type: Generation

| Field | Type | Description |
|---|---|---|
| `request_id` | `str` | Request ID |
| `type` | `str \| None` | Generation type |
| `status` | `"queued" \| "running" \| "succeeded" \| "failed"` | Current status |
| `outputs` | `List[GenerationOutput]` | Output items |
| `usage` | `GenerationUsage \| None` | Credits consumed |
| `error` | `GenerationError \| None` | Error info if failed |
| `created_at` | `str \| None` | Creation time |
| `finished_at` | `str \| None` | Completion time |

Convenience: `gen.url`, `gen.urls`, `gen.credits`.

## Example

```python
resp = client.images.submit(model="image-pro-1", prompt="A cat")
print(f"Submitted: {resp.request_id}")

import time
while True:
    gen = client.generations.get(resp.request_id)
    print(f"Status: {gen.status}")
    if gen.status in ("succeeded", "failed"):
        break
    time.sleep(3)

if gen.status == "succeeded":
    print(gen.url)
```
