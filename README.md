# PonyFlash — Agent Skill

Generate images, videos, speech audio, and music through AI agents using the [PonyFlash](https://ponyflash.com) Python SDK.

Compatible with the [Agent Skills](https://agentskills.io/specification) open standard. Works with **Claude Code, OpenClaw, Cursor, Codex, Gemini CLI, Windsurf, Cline** and 40+ other AI agents.

## Quick Install

### Git (all agents)

```bash
git clone https://github.com/ponyflash/ponyflash-skill.git ponyflash
```

Then move the `ponyflash` folder into your agent's skills directory (see table below).

### OpenClaw

```bash
# From ClawHub (if published)
clawhub install ponyflash

# Or manually
git clone https://github.com/ponyflash/ponyflash-skill.git ~/.openclaw/skills/ponyflash
```

### Claude Code

```bash
git clone https://github.com/ponyflash/ponyflash-skill.git .claude/skills/ponyflash
```

### Cursor

```bash
git clone https://github.com/ponyflash/ponyflash-skill.git .cursor/skills/ponyflash
```

### Skills directory by agent

| Agent | Project-level | Global |
|-------|--------------|--------|
| Claude Code | `.claude/skills/ponyflash/` | `~/.claude/skills/ponyflash/` |
| OpenClaw | `skills/ponyflash/` | `~/.openclaw/skills/ponyflash/` |
| Cursor | `.cursor/skills/ponyflash/` | `~/.cursor/skills/ponyflash/` |
| Codex | `.codex/skills/ponyflash/` | `~/.codex/skills/ponyflash/` |
| Windsurf | `.windsurf/skills/ponyflash/` | `~/.codeium/windsurf/skills/ponyflash/` |
| Cline | `.cline/skills/ponyflash/` | `~/.cline/skills/ponyflash/` |

## What This Skill Does

Once installed, your AI agent can use the PonyFlash SDK to:

| Capability | Description |
|---|---|
| Image generation | Text-to-image, image editing with mask/reference images |
| Video generation | Text-to-video, first-frame-to-video, OmniHuman, Motion Transfer |
| Speech synthesis | Text-to-speech with voice cloning, emotion & speed control |
| Music generation | Text-to-music with lyrics, style, instrumental mode, continuation |
| Model listing | List available models, get model details and supported modes |
| File management | Upload, list, get, delete files |
| Account | Check credit balance, get recharge link |
| Local video editing | Use `ponyflash.editor` to compose timelines locally with FFmpeg |

## Prerequisites

```bash
pip install ponyflash
export PONYFLASH_API_KEY="rk_xxx"
```

如果需要本地时间线编辑：

```bash
pip install ponyflash[editor]
```
## Quick Example

```python
from ponyflash import PonyFlash

pony_flash = PonyFlash()

# Generate an image
gen = pony_flash.images.generate(
    model="nano-banana-pro",
    prompt="A sunset over mountains",
    resolution="2K",
)
print(gen.url)
```

See [SKILL.md](SKILL.md) for full usage instructions, or browse the [reference/](reference/) directory for detailed API docs.

`ponyflash.editor` 已作为正式能力提供，详细语义与示例见 [reference/editor.md](reference/editor.md)。
## Directory Structure

```
ponyflash/
├── SKILL.md                 # Skill definition (agent reads this)
├── README.md                # This file
├── LICENSE                  # MIT
├── examples/
│   ├── quickstart.py        # Minimal working example
│   └── advanced.md          # Advanced usage guide
└── reference/
    ├── images.md            # Image generation API
    ├── video.md             # Video generation API
    ├── speech.md            # Speech synthesis API
    ├── music.md             # Music generation API
    ├── models.md            # Model listing API
    ├── files.md             # File management API
    ├── account.md           # Account & credits API
    └── models/
        ├── INDEX.md         # Model catalog overview
        └── (per-model docs)
```

## Contributing

1. Fork this repo
2. Add or update skill content
3. Follow the [Agent Skills specification](https://agentskills.io/specification)
4. Submit a PR

## License

[MIT](LICENSE)
