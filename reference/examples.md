# Examples

These examples help an agent map user requests to the stable script entrypoints.

## Example 1: Check whether FFmpeg is available

User intent:

> Check whether this machine can run ffmpeg directly

Recommended command:

```bash
bash scripts/check_ffmpeg.sh
```

If only basic editing support is required:

```bash
bash scripts/check_ffmpeg.sh --profile basic
```

If dependencies are missing, print the install plan first:

```bash
bash scripts/install_ffmpeg.sh
```

Only execute the install after explicit user approval:

```bash
bash scripts/install_ffmpeg.sh --execute
```

If subtitle burn-in may be needed later, run an extra check:

```bash
bash scripts/check_ffmpeg.sh --require-subtitles-filter
```

## Example 2: Keep 8 seconds starting at 00:00:05

User intent:

> Cut an 8-second clip starting from 00:00:05 in `input.mp4`

Recommended command:

```bash
bash scripts/media_ops.sh clip --input "input.mp4" --output "clip.mp4" --start "00:00:05" --duration "8"
```

## Example 3: Fast near-lossless trimming

User intent:

> I only care about speed and I can tolerate keyframe-boundary inaccuracies

Recommended command:

```bash
bash scripts/media_ops.sh clip --mode copy --input "input.mp4" --output "clip.mp4" --start "00:00:05" --duration "8"
```

## Example 4: Concatenate two clips

User intent:

> Merge `part1.mp4` and `part2.mp4` into one output file

Recommended command:

```bash
bash scripts/media_ops.sh concat --input "part1.mp4" --input "part2.mp4" --output "merged.mp4"
```

If that fails, retry with re-encoding:

```bash
bash scripts/media_ops.sh concat --mode reencode --input "part1.mp4" --input "part2.mp4" --output "merged.mp4"
```

## Example 5: Extract audio

User intent:

> Export the audio track from the video

Recommended command:

```bash
bash scripts/media_ops.sh extract-audio --input "input.mp4" --output "audio.m4a"
```

## Example 6: Convert MOV to a more compatible MP4

User intent:

> Convert this MOV file into a more standard MP4

Recommended command:

```bash
bash scripts/media_ops.sh transcode --input "input.mov" --output "output.mp4"
```

## Example 7: Export a cover frame

User intent:

> Grab a cover image at the 3-second mark

Recommended command:

```bash
bash scripts/media_ops.sh frame --input "input.mp4" --output "cover.jpg" --time "00:00:03"
```

## Example 8: Inspect media before deciding what to do

User intent:

> Check the codec and duration of this video first

Recommended command:

```bash
bash scripts/media_ops.sh probe --input "input.mp4"
```

## Example 9: Allow overwriting existing output

User intent:

> Overwrite the existing output file directly

Add:

```bash
--overwrite
```

For example:

```bash
bash scripts/media_ops.sh transcode --input "input.mov" --output "output.mp4" --overwrite
```

## Example 10: Verify whether subtitle burn-in is supported

User intent:

> Confirm whether this machine can burn in SRT subtitles directly with ffmpeg

Recommended command:

```bash
bash scripts/check_ffmpeg.sh --require-subtitles-filter
```

If that fails, inspect the installation plan first:

```bash
bash scripts/install_ffmpeg.sh
```

## Example 11: Check whether simple text overlays are possible

User intent:

> I do not necessarily need SRT support. I just need to place a few lines of text at the bottom.

Recommended command:

```bash
bash scripts/check_ffmpeg.sh --require-subtitle-support
```

## Example 12: Install FFmpeg and verify subtitle capability

User intent:

> Install an FFmpeg build that can handle subtitle burn-in

Recommended command:

```bash
bash scripts/install_ffmpeg.sh --execute
```

Notes:

- the installer verifies the `subtitles` filter after installation by default
- if verification still fails, the package-manager build is probably incomplete

## Example 13: Install only enough for stable basic editing

User intent:

> Install an FFmpeg build that is stable for editing and transcoding, but subtitles are optional

Recommended command:

```bash
bash scripts/install_ffmpeg.sh --profile basic --execute
```

## Example 14: Install the full version on Windows

User intent:

> I am on Windows. Install the full FFmpeg build for me.

Recommended command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install_ffmpeg.ps1 -Profile full -Execute
```

## Example 15: Check basic editing support on Windows

User intent:

> Confirm whether this Windows machine supports basic editing

Recommended command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check_ffmpeg.ps1 -Profile basic
```

## Example 16: Generate adaptive ASS subtitles for 9:16 output

User intent:

> Burn subtitles into a portrait video and keep long lines from overflowing the frame

Recommended command:

```bash
python3 scripts/build_ass_subtitles.py \
  --events-json "events.json" \
  --output-ass "subtitles.ass" \
  --video-width 1080 \
  --video-height 1920 \
  --latin-font-file "assets/fonts/Adamina-Regular.ttf" \
  --cjk-font-file "assets/fonts/NotoSansSC-Regular.ttf"
```

Notes:

- the script uses a `90%` safe-width rule by default
- it pre-wraps text based on measured font width before generating `.ass`
- after generating `.ass`, burn it in with `ffmpeg -vf subtitles=...`
