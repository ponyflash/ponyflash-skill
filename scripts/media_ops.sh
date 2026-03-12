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
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
