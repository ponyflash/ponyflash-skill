param(
  [switch]$Quiet,
  [ValidateSet("basic", "full")]
  [string]$Profile,
  [switch]$RequireBasicEditing,
  [switch]$RequireSubtitleSupport,
  [switch]$RequireSubtitlesFilter,
  [switch]$RequireDrawtextFilter
)

if ($Profile -eq "basic") {
  $RequireBasicEditing = $true
} elseif ($Profile -eq "full") {
  $RequireBasicEditing = $true
  $RequireSubtitlesFilter = $true
}

function Test-Filter {
  param(
    [string]$Name
  )

  $filters = & ffmpeg -hide_banner -filters 2>$null
  return ($filters | Select-String -Pattern ("^\s*\S+\s+" + [regex]::Escape($Name) + "\s") -Quiet)
}

function Test-Encoder {
  param(
    [string]$Name
  )

  $encoders = & ffmpeg -hide_banner -encoders 2>$null
  return ($encoders | Select-String -Pattern ("^\s*\S+\s+" + [regex]::Escape($Name) + "\s") -Quiet)
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue

$missing = $false
$capabilityMissing = $false

if (-not $Quiet) {
  Write-Output "platform=$([System.Environment]::OSVersion.Platform)"
  Write-Output "path=$env:PATH"
}

if ($ffmpeg) {
  $ffmpegVersion = (& ffmpeg -version 2>$null | Select-Object -First 1)
  $subtitlesFilter = if (Test-Filter "subtitles") { "available" } else { "missing" }
  $drawtextFilter = if (Test-Filter "drawtext") { "available" } else { "missing" }
  $libx264Encoder = if (Test-Encoder "libx264") { "available" } else { "missing" }
  $aacEncoder = if (Test-Encoder "aac") { "available" } else { "missing" }
  $basicEditingSupport = if ($libx264Encoder -eq "available" -and $aacEncoder -eq "available") { "available" } else { "missing" }

  if ($subtitlesFilter -eq "available" -and $drawtextFilter -eq "available") {
    $subtitleSupport = "full"
  } elseif ($subtitlesFilter -eq "available") {
    $subtitleSupport = "subtitles_only"
  } elseif ($drawtextFilter -eq "available") {
    $subtitleSupport = "drawtext_only"
  } else {
    $subtitleSupport = "missing"
  }

  if (-not $Quiet) {
    Write-Output "ffmpeg=installed"
    Write-Output "ffmpeg_path=$($ffmpeg.Path)"
    Write-Output "ffmpeg_version=$ffmpegVersion"
    Write-Output "libx264_encoder=$libx264Encoder"
    Write-Output "aac_encoder=$aacEncoder"
    Write-Output "basic_editing_support=$basicEditingSupport"
    Write-Output "subtitles_filter=$subtitlesFilter"
    Write-Output "drawtext_filter=$drawtextFilter"
    Write-Output "subtitle_support=$subtitleSupport"
  }

  if ($RequireBasicEditing -and $basicEditingSupport -ne "available") {
    Write-Error "Missing capability: basic editing support requires libx264 and aac encoders."
    $capabilityMissing = $true
  }

  if ($RequireSubtitleSupport -and $subtitleSupport -eq "missing") {
    Write-Error "Missing capability: subtitles or drawtext filter is required."
    $capabilityMissing = $true
  }

  if ($RequireSubtitlesFilter -and $subtitlesFilter -ne "available") {
    Write-Error "Missing capability: subtitles filter is required."
    $capabilityMissing = $true
  }

  if ($RequireDrawtextFilter -and $drawtextFilter -ne "available") {
    Write-Error "Missing capability: drawtext filter is required."
    $capabilityMissing = $true
  }
} else {
  Write-Output "ffmpeg=missing"
  $missing = $true
}

if ($ffprobe) {
  if (-not $Quiet) {
    $ffprobeVersion = (& ffprobe -version 2>$null | Select-Object -First 1)
    Write-Output "ffprobe=installed"
    Write-Output "ffprobe_path=$($ffprobe.Path)"
    Write-Output "ffprobe_version=$ffprobeVersion"
  }
} else {
  Write-Output "ffprobe=missing"
  $missing = $true
}

if ($missing) {
  if (-not $Quiet) {
    Write-Output "status=missing_dependencies"
  }
  exit 1
}

if ($capabilityMissing) {
  if (-not $Quiet) {
    Write-Output "status=missing_capabilities"
  }
  exit 3
}

if (-not $Quiet) {
  Write-Output "status=ready"
}

exit 0
