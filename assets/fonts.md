# Font Assets

This directory documents the default subtitle font assets expected by the skill.

## Current Expected Fonts

- `assets/fonts/Adamina-Regular.ttf`
- `assets/fonts/NotoSansSC-Regular.ttf`

## Default Font Strategy

- English, numbers, and Latin characters: prefer `Adamina`
- Chinese characters: prefer `Noto Sans SC`

## Intended Usage

Subtitle generation scripts should prefer the font files under `assets/fonts/` instead of relying directly on system fonts.

## Recommended References

- Primary Latin font: `assets/fonts/Adamina-Regular.ttf`
- CJK fallback font: `assets/fonts/NotoSansSC-Regular.ttf`

In `ffmpeg subtitles` / `libass` workflows, the recommended approach is:

1. Add `assets/fonts/` to the font search path through `fontsdir`
2. Set the main style `Fontname` to `Adamina`
3. Use `scripts/build_ass_subtitles.py` to insert `{\fnNoto Sans SC}` for Chinese segments and `{\fnAdamina}` for English segments explicitly

## Notes

- `fontsdir` should contain only font files when possible; avoid mixing in text files such as `README.md`
- On macOS with `libass + coretext`, do not rely on CSS-like automatic font fallback ordering
- If you need stable matching for `NotoSansSC-Regular.ttf`, emit explicit font tags rather than assuming `fontsdir` alone will resolve it
