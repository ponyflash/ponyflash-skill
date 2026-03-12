#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  media_ops.sh <command> [options]

Commands:
  help
  probe --input <file>
  clip --input <file> --output <file> --start <time> --duration <time> [--mode reencode|copy] [--overwrite]
  concat --input <file> --input <file> --output <file> [--mode copy|reencode] [--overwrite]
  extract-audio --input <file> --output <file> [--audio-codec <codec>] [--bitrate <rate>] [--overwrite]
  transcode --input <file> --output <file> [--video-codec <codec>] [--audio-codec <codec>] [--crf <value>] [--preset <name>] [--bitrate <rate>] [--overwrite]
  frame --input <file> --output <file> --time <time> [--overwrite]
  subtitle-burn --input <video> --subtitle-file <file> --output <file> [--ass-output <file>] [--latin-font-file <file>] [--cjk-font-file <file>] [--wrap-width-ratio <ratio>] [--font-size <px>] [--margin-v <px>] [--margin-l <px>] [--margin-r <px>] [--outline <px>] [--shadow <px>] [--blur <px>] [--overwrite]
EOF
}

ensure_deps() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Missing dependency: ffmpeg" >&2
    exit 1
  fi

  if ! command -v ffprobe >/dev/null 2>&1; then
    echo "Missing dependency: ffprobe" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Input file not found: $path" >&2
    exit 1
  fi
}

overwrite_flag() {
  if [[ "${1:-0}" -eq 1 ]]; then
    echo "-y"
  else
    echo "-n"
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing dependency: $command_name" >&2
    exit 1
  fi
}

probe_video_dimensions() {
  local input_path="$1"
  ffprobe -hide_banner -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$input_path"
}

escape_filter_path() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//:/\\:}"
  value="${value//,/\\,}"
  value="${value//[/\\[}"
  value="${value//]/\\]}"
  printf '%s' "$value"
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
fonts_dir="$repo_root/assets/fonts"
default_latin_font="$fonts_dir/Adamina-Regular.ttf"
default_cjk_font="$fonts_dir/NotoSansSC-Regular.ttf"

cmd="${1:-help}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$cmd" in
  help|-h|--help)
    usage
    exit 0
    ;;
  probe)
    ensure_deps
    input=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          input="$2"
          shift 2
          ;;
        *)
          echo "Unknown option for probe: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$input" ]] || { echo "probe requires --input" >&2; exit 2; }
    require_file "$input"

    ffprobe -hide_banner -v error -show_format -show_streams "$input"
    ;;
  clip)
    ensure_deps
    input=""
    output=""
    start=""
    duration=""
    mode="reencode"
    overwrite=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          input="$2"
          shift 2
          ;;
        --output)
          output="$2"
          shift 2
          ;;
        --start)
          start="$2"
          shift 2
          ;;
        --duration)
          duration="$2"
          shift 2
          ;;
        --mode)
          mode="$2"
          shift 2
          ;;
        --overwrite)
          overwrite=1
          shift
          ;;
        *)
          echo "Unknown option for clip: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$input" ]] || { echo "clip requires --input" >&2; exit 2; }
    [[ -n "$output" ]] || { echo "clip requires --output" >&2; exit 2; }
    [[ -n "$start" ]] || { echo "clip requires --start" >&2; exit 2; }
    [[ -n "$duration" ]] || { echo "clip requires --duration" >&2; exit 2; }
    require_file "$input"

    if [[ "$mode" == "copy" ]]; then
      ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -ss "$start" -i "$input" -t "$duration" -c copy "$output"
    elif [[ "$mode" == "reencode" ]]; then
      ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -i "$input" -ss "$start" -t "$duration" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k -movflags +faststart "$output"
    else
      echo "Unsupported clip mode: $mode" >&2
      exit 2
    fi
    ;;
  concat)
    ensure_deps
    inputs=()
    output=""
    mode="copy"
    overwrite=0
    list_file=""

    cleanup() {
      [[ -n "$list_file" && -f "$list_file" ]] && rm -f "$list_file"
    }
    trap cleanup EXIT

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          inputs+=("$2")
          shift 2
          ;;
        --output)
          output="$2"
          shift 2
          ;;
        --mode)
          mode="$2"
          shift 2
          ;;
        --overwrite)
          overwrite=1
          shift
          ;;
        *)
          echo "Unknown option for concat: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ ${#inputs[@]} -ge 2 ]] || { echo "concat requires at least two --input values" >&2; exit 2; }
    [[ -n "$output" ]] || { echo "concat requires --output" >&2; exit 2; }

    list_file="$(mktemp)"
    for input in "${inputs[@]}"; do
      require_file "$input"
      escaped_path="${input//\'/\'\\\'\'}"
      printf "file '%s'\n" "$escaped_path" >>"$list_file"
    done

    if [[ "$mode" == "copy" ]]; then
      ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -f concat -safe 0 -i "$list_file" -c copy "$output"
    elif [[ "$mode" == "reencode" ]]; then
      ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -f concat -safe 0 -i "$list_file" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k -movflags +faststart "$output"
    else
      echo "Unsupported concat mode: $mode" >&2
      exit 2
    fi
    ;;
  extract-audio)
    ensure_deps
    input=""
    output=""
    audio_codec="aac"
    bitrate="192k"
    overwrite=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          input="$2"
          shift 2
          ;;
        --output)
          output="$2"
          shift 2
          ;;
        --audio-codec)
          audio_codec="$2"
          shift 2
          ;;
        --bitrate)
          bitrate="$2"
          shift 2
          ;;
        --overwrite)
          overwrite=1
          shift
          ;;
        *)
          echo "Unknown option for extract-audio: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$input" ]] || { echo "extract-audio requires --input" >&2; exit 2; }
    [[ -n "$output" ]] || { echo "extract-audio requires --output" >&2; exit 2; }
    require_file "$input"

    if [[ "$audio_codec" == "copy" ]]; then
      ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -i "$input" -vn -c:a copy "$output"
    else
      ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -i "$input" -vn -c:a "$audio_codec" -b:a "$bitrate" "$output"
    fi
    ;;
  transcode)
    ensure_deps
    input=""
    output=""
    video_codec="libx264"
    audio_codec="aac"
    crf="18"
    preset="medium"
    bitrate="192k"
    overwrite=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          input="$2"
          shift 2
          ;;
        --output)
          output="$2"
          shift 2
          ;;
        --video-codec)
          video_codec="$2"
          shift 2
          ;;
        --audio-codec)
          audio_codec="$2"
          shift 2
          ;;
        --crf)
          crf="$2"
          shift 2
          ;;
        --preset)
          preset="$2"
          shift 2
          ;;
        --bitrate)
          bitrate="$2"
          shift 2
          ;;
        --overwrite)
          overwrite=1
          shift
          ;;
        *)
          echo "Unknown option for transcode: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$input" ]] || { echo "transcode requires --input" >&2; exit 2; }
    [[ -n "$output" ]] || { echo "transcode requires --output" >&2; exit 2; }
    require_file "$input"

    ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -i "$input" -c:v "$video_codec" -preset "$preset" -crf "$crf" -c:a "$audio_codec" -b:a "$bitrate" -movflags +faststart "$output"
    ;;
  frame)
    ensure_deps
    input=""
    output=""
    time_value=""
    overwrite=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          input="$2"
          shift 2
          ;;
        --output)
          output="$2"
          shift 2
          ;;
        --time)
          time_value="$2"
          shift 2
          ;;
        --overwrite)
          overwrite=1
          shift
          ;;
        *)
          echo "Unknown option for frame: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$input" ]] || { echo "frame requires --input" >&2; exit 2; }
    [[ -n "$output" ]] || { echo "frame requires --output" >&2; exit 2; }
    [[ -n "$time_value" ]] || { echo "frame requires --time" >&2; exit 2; }
    require_file "$input"

    ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -ss "$time_value" -i "$input" -frames:v 1 "$output"
    ;;
  subtitle-burn)
    ensure_deps
    require_command python3

    input=""
    subtitle_file=""
    output=""
    ass_output=""
    latin_font_file="$default_latin_font"
    cjk_font_file="$default_cjk_font"
    wrap_width_ratio=""
    font_size=""
    margin_v=""
    margin_l=""
    margin_r=""
    outline=""
    shadow=""
    blur=""
    overwrite=0
    temp_ass_output=""

    cleanup_subtitle_burn() {
      [[ -n "$temp_ass_output" && -f "$temp_ass_output" ]] && rm -f "$temp_ass_output"
    }
    trap cleanup_subtitle_burn EXIT

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --input)
          input="$2"
          shift 2
          ;;
        --subtitle-file)
          subtitle_file="$2"
          shift 2
          ;;
        --output)
          output="$2"
          shift 2
          ;;
        --ass-output)
          ass_output="$2"
          shift 2
          ;;
        --latin-font-file)
          latin_font_file="$2"
          shift 2
          ;;
        --cjk-font-file)
          cjk_font_file="$2"
          shift 2
          ;;
        --wrap-width-ratio)
          wrap_width_ratio="$2"
          shift 2
          ;;
        --font-size)
          font_size="$2"
          shift 2
          ;;
        --margin-v)
          margin_v="$2"
          shift 2
          ;;
        --margin-l)
          margin_l="$2"
          shift 2
          ;;
        --margin-r)
          margin_r="$2"
          shift 2
          ;;
        --outline)
          outline="$2"
          shift 2
          ;;
        --shadow)
          shadow="$2"
          shift 2
          ;;
        --blur)
          blur="$2"
          shift 2
          ;;
        --overwrite)
          overwrite=1
          shift
          ;;
        *)
          echo "Unknown option for subtitle-burn: $1" >&2
          exit 2
          ;;
      esac
    done

    [[ -n "$input" ]] || { echo "subtitle-burn requires --input" >&2; exit 2; }
    [[ -n "$subtitle_file" ]] || { echo "subtitle-burn requires --subtitle-file" >&2; exit 2; }
    [[ -n "$output" ]] || { echo "subtitle-burn requires --output" >&2; exit 2; }
    require_file "$input"
    require_file "$subtitle_file"

    bash "$script_dir/check_ffmpeg.sh" --require-subtitles-filter >/dev/null

    subtitle_ext="$(printf '%s' "${subtitle_file##*.}" | tr '[:upper:]' '[:lower:]')"
    video_dims="$(probe_video_dimensions "$input")"
    [[ -n "$video_dims" ]] || { echo "Could not probe input video dimensions." >&2; exit 1; }
    video_width="${video_dims%x*}"
    video_height="${video_dims#*x}"
    [[ -n "$video_width" && -n "$video_height" && "$video_width" != "$video_dims" ]] || {
      echo "Could not parse probed video dimensions: $video_dims" >&2
      exit 1
    }

    ass_source="$subtitle_file"
    if [[ "$subtitle_ext" != "ass" ]]; then
      require_file "$latin_font_file"
      require_file "$cjk_font_file"

      if [[ -n "$ass_output" ]]; then
        ass_source="$ass_output"
      else
        temp_ass_output="$(mktemp "${TMPDIR:-/tmp}/ponyflash-subtitles.XXXXXX.ass")"
        ass_source="$temp_ass_output"
      fi

      build_args=(
        "$script_dir/build_ass_subtitles.py"
        --subtitle-file "$subtitle_file"
        --output-ass "$ass_source"
        --video-width "$video_width"
        --video-height "$video_height"
        --latin-font-file "$latin_font_file"
        --cjk-font-file "$cjk_font_file"
      )

      [[ -n "$wrap_width_ratio" ]] && build_args+=(--wrap-width-ratio "$wrap_width_ratio")
      [[ -n "$font_size" ]] && build_args+=(--font-size "$font_size")
      [[ -n "$margin_v" ]] && build_args+=(--margin-v "$margin_v")
      [[ -n "$margin_l" ]] && build_args+=(--margin-l "$margin_l")
      [[ -n "$margin_r" ]] && build_args+=(--margin-r "$margin_r")
      [[ -n "$outline" ]] && build_args+=(--outline "$outline")
      [[ -n "$shadow" ]] && build_args+=(--shadow "$shadow")
      [[ -n "$blur" ]] && build_args+=(--blur "$blur")

      python3 "${build_args[@]}"
    fi

    ffmpeg "$(overwrite_flag "$overwrite")" -hide_banner -i "$input" \
      -vf "subtitles=$(escape_filter_path "$ass_source"):fontsdir=$(escape_filter_path "$fonts_dir")" \
      -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k -movflags +faststart "$output"
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
