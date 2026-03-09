# Speech API Reference

## Methods

### `client.speech.submit(**kwargs) -> CreateResponse`

Submits a speech synthesis request. Returns immediately.

### `client.speech.generate(**kwargs) -> Generation`

Submits and polls until completion.

## Parameters

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `model` | `str` | Yes | — | Model ID (e.g. `"speech-v1"`) |
| `input` | `str` | Yes | — | Text to synthesize |
| `voice` | `str` | Yes | — | Voice ID (e.g. `"alloy"`, `"nova"`) |
| `language` | `str` | No | — | Language code |
| `speed` | `float` | No | — | Playback speed multiplier |
| `pitch` | `int` | No | — | Pitch adjustment |
| `emotion` | `str` | No | — | Emotion (e.g. `"excited"`, `"calm"`) |
| `instructions` | `str` | No | — | Style instructions |
| `voice_settings` | `VoiceSettings` | No | — | Fine-grained voice control |
| `sample_rate` | `int` | No | — | Audio sample rate in Hz |
| `format` | `str` | No | — | Output format (e.g. `"mp3"`, `"wav"`) |

### VoiceSettings (TypedDict)

| Field | Type | Description |
|---|---|---|
| `stability` | `float` | Voice stability (0.0-1.0) |
| `similarity_boost` | `float` | Voice similarity (0.0-1.0) |
| `style` | `float` | Style exaggeration (0.0-1.0) |
| `use_speaker_boost` | `bool` | Enable speaker boost |

`generate()` adds:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `poll_interval` | `float` | `2.0` | Seconds between status checks |
| `timeout` | `float` | `300.0` | Max seconds to wait (5 min) |

## Example

```python
gen = client.speech.generate(
    model="speech-v1",
    input="Hello, welcome to PonyFlash!",
    voice="alloy",
    speed=1.0,
    format="mp3",
)
print(gen.url)
```
