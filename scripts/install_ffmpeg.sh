#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install_ffmpeg.sh [--execute] [--yes] [--profile basic|full] [--skip-subtitle-check] [--help]

Options:
  --execute              Run the installation command. Without this flag, only print the plan.
  --yes                  Pass non-interactive approval flags when supported.
  --profile <name>       Install profile: basic or full. Defaults to full.
  --skip-subtitle-check  Skip verifying subtitle-related filters after install.
  --help                 Show this help message.
EOF
}

execute=0
assume_yes=0
profile="full"
require_subtitles_filter=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute)
      execute=1
      shift
      ;;
    --yes|-y)
      assume_yes=1
      shift
      ;;
    --profile)
      case "${2:-}" in
        basic|full)
          profile="$2"
          ;;
        *)
          echo "Unsupported profile: ${2:-}" >&2
          usage >&2
          exit 2
          ;;
      esac
      shift 2
      ;;
    --skip-subtitle-check)
      require_subtitles_filter=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

choose_sudo_prefix() {
  if [[ "$(id -u)" -eq 0 ]]; then
    echo ""
  elif command -v sudo >/dev/null 2>&1; then
    echo "sudo"
  else
    echo ""
  fi
}

run_or_print() {
  local command_string="$1"

  if [[ $execute -eq 1 ]]; then
    echo "[run] $command_string"
    bash -lc "$command_string"
  else
    echo "[plan] $command_string"
  fi
}

check_args=()
check_args+=(--profile "$profile")
if [[ $require_subtitles_filter -eq 0 ]]; then
  check_args=()
  [[ "$profile" == "basic" ]] && check_args+=(--profile basic)
fi

static_fallback_needed=0

linux_static_install() {
  local arch_name
  case "$(uname -m 2>/dev/null)" in
    x86_64|amd64)
      arch_name="amd64"
      ;;
    aarch64|arm64)
      arch_name="arm64"
      ;;
    armv7l|armhf)
      arch_name="armhf"
      ;;
    *)
      echo "Unsupported Linux architecture for static fallback: $(uname -m 2>/dev/null)" >&2
      return 2
      ;;
  esac

  local downloader=""
  if command -v curl >/dev/null 2>&1; then
    downloader="curl -L"
  elif command -v wget >/dev/null 2>&1; then
    downloader="wget -O-"
  else
    echo "Need curl or wget for Linux static fallback." >&2
    return 2
  fi

  local install_root="$HOME/.local/ffmpeg-full"
  local bin_root="$HOME/.local/bin"
  local archive_url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-${arch_name}-static.tar.xz"
  local plan_command="mkdir -p \"$install_root\" \"$bin_root\" && tmpdir=\$(mktemp -d) && ${downloader} \"$archive_url\" > \"\$tmpdir/ffmpeg.tar.xz\" && tar -xf \"\$tmpdir/ffmpeg.tar.xz\" -C \"\$tmpdir\" && extracted_dir=\$(printf '%s\n' \"\$tmpdir\"/ffmpeg-*-static | awk 'NR==1 { print \$0 }') && rm -rf \"$install_root\" && mkdir -p \"$install_root\" && cp -R \"\$extracted_dir\"/. \"$install_root\"/ && ln -sf \"$install_root/ffmpeg\" \"$bin_root/ffmpeg\" && ln -sf \"$install_root/ffprobe\" \"$bin_root/ffprobe\""

  run_or_print "$plan_command"

  if [[ $execute -eq 0 ]]; then
    echo "[note] Add \"$HOME/.local/bin\" to PATH if needed."
  fi
}

windows_install_plan() {
  if command -v winget >/dev/null 2>&1; then
    run_or_print "winget install -e --id Gyan.FFmpeg.Shared"
  elif command -v scoop >/dev/null 2>&1; then
    run_or_print "scoop install ffmpeg-full"
  elif command -v choco >/dev/null 2>&1; then
    run_or_print "choco install ffmpeg-full -y"
  else
    echo "Unsupported Windows package manager. Install one of: winget, scoop, choco."
    echo "Recommended package: Gyan.FFmpeg.Shared or ffmpeg-full."
    exit 2
  fi
}

if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
  if bash "$(dirname "$0")/check_ffmpeg.sh" "${check_args[@]}"; then
    echo "ffmpeg and ffprobe are already installed with the required capabilities."
    exit 0
  fi

  echo
  echo "ffmpeg is installed, but the current build is missing required capabilities for profile: $profile"
  echo "The installer will attempt to refresh or reinstall ffmpeg."
fi

os_name="$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')"
sudo_prefix="$(choose_sudo_prefix)"
ffmpeg_already_installed=0
command -v ffmpeg >/dev/null 2>&1 && ffmpeg_already_installed=1

case "$os_name" in
  darwin)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew is not installed. Install Homebrew first:"
      echo "https://brew.sh/"
      exit 2
    fi
    if brew list --versions ffmpeg-full >/dev/null 2>&1; then
      run_or_print "brew reinstall ffmpeg-full"
    else
      run_or_print "brew install ffmpeg-full"
    fi
    run_or_print "brew link --overwrite --force ffmpeg-full"
    ;;
  linux)
    if command -v apt-get >/dev/null 2>&1; then
      yes_flag=""
      [[ $assume_yes -eq 1 ]] && yes_flag="-y"
      run_or_print "${sudo_prefix:+$sudo_prefix }apt-get update"
      if [[ $ffmpeg_already_installed -eq 1 ]]; then
        run_or_print "${sudo_prefix:+$sudo_prefix }apt-get install $yes_flag --reinstall ffmpeg"
      else
        run_or_print "${sudo_prefix:+$sudo_prefix }apt-get install $yes_flag ffmpeg"
      fi
    elif command -v dnf >/dev/null 2>&1; then
      yes_flag=""
      [[ $assume_yes -eq 1 ]] && yes_flag="-y"
      if [[ $ffmpeg_already_installed -eq 1 ]]; then
        run_or_print "${sudo_prefix:+$sudo_prefix }dnf reinstall $yes_flag ffmpeg"
      else
        run_or_print "${sudo_prefix:+$sudo_prefix }dnf install $yes_flag ffmpeg"
      fi
    elif command -v yum >/dev/null 2>&1; then
      yes_flag=""
      [[ $assume_yes -eq 1 ]] && yes_flag="-y"
      if [[ $ffmpeg_already_installed -eq 1 ]]; then
        run_or_print "${sudo_prefix:+$sudo_prefix }yum reinstall $yes_flag ffmpeg"
      else
        run_or_print "${sudo_prefix:+$sudo_prefix }yum install $yes_flag ffmpeg"
      fi
    elif command -v pacman >/dev/null 2>&1; then
      yes_flag=""
      [[ $assume_yes -eq 1 ]] && yes_flag="--noconfirm"
      run_or_print "${sudo_prefix:+$sudo_prefix }pacman -Sy $yes_flag ffmpeg"
    elif command -v apk >/dev/null 2>&1; then
      yes_flag=""
      [[ $assume_yes -eq 1 ]] && yes_flag="--no-interactive"
      run_or_print "${sudo_prefix:+$sudo_prefix }apk add $yes_flag ffmpeg"
    else
      echo "Unsupported Linux package manager."
      echo "Open the official guide:"
      echo "https://ffmpeg.org/download.html"
      exit 2
    fi

    if [[ "$profile" == "full" ]]; then
      echo
      echo "If the distro package still lacks subtitle filters, a static full build fallback will be used."
      static_fallback_needed=1
    fi
    ;;
  msys*|mingw*|cygwin*|nt)
    windows_install_plan
    ;;
  *)
    echo "Unsupported platform: $os_name"
    echo "Open the official guide:"
    echo "https://ffmpeg.org/download.html"
    exit 2
    ;;
esac

if [[ $execute -eq 0 ]]; then
  echo
  echo "Installation plan printed only."
  echo "Run again with --execute to perform the installation."
  exit 0
fi

echo
echo "Verifying installation..."
if bash "$(dirname "$0")/check_ffmpeg.sh" "${check_args[@]}"; then
  exit 0
fi

if [[ $static_fallback_needed -eq 1 ]]; then
  echo
  echo "Distro ffmpeg is still missing full-profile capabilities. Falling back to a static full build..."
  linux_static_install
  echo
  echo "Verifying static fallback..."
  if PATH="$HOME/.local/bin:$PATH" bash "$(dirname "$0")/check_ffmpeg.sh" "${check_args[@]}"; then
    exit 0
  fi
fi

if [[ "$profile" == "full" ]]; then
  echo
  echo "ffmpeg is installed, but the current build still lacks the required full-profile capabilities."
  echo "Use a build that includes libx264, aac, libass, and freetype support, or follow the official guide:"
  echo "https://ffmpeg.org/download.html"
elif [[ "$profile" == "basic" ]]; then
  echo
  echo "ffmpeg is installed, but the current build still lacks the required basic editing capabilities."
  echo "Use a build that includes libx264 and aac support, or follow the official guide:"
  echo "https://ffmpeg.org/download.html"
fi

exit 3
