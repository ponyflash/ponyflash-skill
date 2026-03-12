param(
  [switch]$Execute,
  [switch]$Yes,
  [ValidateSet("basic", "full")]
  [string]$Profile = "full",
  [switch]$SkipSubtitleCheck
)

$checkArgs = @()
if (-not $SkipSubtitleCheck) {
  $checkArgs += "-Profile", $Profile
} elseif ($Profile -eq "basic") {
  $checkArgs += "-Profile", "basic"
}

function Invoke-OrPlan {
  param(
    [string]$Command
  )

  if ($Execute) {
    Write-Output "[run] $Command"
    powershell -NoProfile -ExecutionPolicy Bypass -Command $Command
  } else {
    Write-Output "[plan] $Command"
  }
}

function Install-WindowsFfmpeg {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Invoke-OrPlan 'winget install -e --id Gyan.FFmpeg.Shared'
    return
  }

  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Invoke-OrPlan 'scoop install ffmpeg-full'
    return
  }

  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Invoke-OrPlan 'choco install ffmpeg-full -y'
    return
  }

  throw "Unsupported Windows package manager. Install winget, scoop, or chocolatey first."
}

if ((Get-Command ffmpeg -ErrorAction SilentlyContinue) -and (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
  $checkScript = Join-Path $PSScriptRoot "check_ffmpeg.ps1"
  $process = Start-Process powershell -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $checkScript) + $checkArgs -Wait -PassThru -NoNewWindow
  if ($process.ExitCode -eq 0) {
    Write-Output "ffmpeg and ffprobe are already installed with the required capabilities."
    exit 0
  }

  Write-Output ""
  Write-Output "ffmpeg is installed, but the current build is missing required capabilities for profile: $Profile"
  Write-Output "The installer will attempt to refresh or reinstall ffmpeg."
}

Install-WindowsFfmpeg

if (-not $Execute) {
  Write-Output ""
  Write-Output "Installation plan printed only."
  Write-Output "Run again with -Execute to perform the installation."
  exit 0
}

Write-Output ""
Write-Output "Verifying installation..."
$checkScript = Join-Path $PSScriptRoot "check_ffmpeg.ps1"
$process = Start-Process powershell -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $checkScript) + $checkArgs -Wait -PassThru -NoNewWindow
if ($process.ExitCode -eq 0) {
  exit 0
}

if ($Profile -eq "full") {
  Write-Output ""
  Write-Output "ffmpeg is installed, but the current build still lacks the required full-profile capabilities."
  Write-Output "Use a build that includes libx264, aac, libass, and freetype support, or follow the official guide:"
  Write-Output "https://ffmpeg.org/download.html"
} else {
  Write-Output ""
  Write-Output "ffmpeg is installed, but the current build still lacks the required basic editing capabilities."
  Write-Output "Use a build that includes libx264 and aac support, or follow the official guide:"
  Write-Output "https://ffmpeg.org/download.html"
}

exit 3
