<#
Generates every platform launcher icon from the Android foreground PNG.
Run from the repository root: .\tool\generate_launcher_icons.ps1
#>

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'android\app\src\main\res\drawable\ic_launcher_foreground.png'
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)

function Get-VisibleBounds {
  param([System.Drawing.Bitmap] $Bitmap)
  $left = $Bitmap.Width
  $top = $Bitmap.Height
  $right = -1
  $bottom = -1
  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      if ($Bitmap.GetPixel($x, $y).A -gt 0) {
        $left = [Math]::Min($left, $x)
        $top = [Math]::Min($top, $y)
        $right = [Math]::Max($right, $x)
        $bottom = [Math]::Max($bottom, $y)
      }
    }
  }
  if ($right -lt $left -or $bottom -lt $top) { throw 'The launcher source has no visible pixels.' }
  $bounds = [System.Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
  if ($bounds.Width -ne $bounds.Height) { throw 'The visible launcher artwork must be square.' }
  return $bounds
}

$sourceBounds = Get-VisibleBounds $source

function New-LauncherBitmap {
  param([int] $Size)
  $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $Size, $Size), $sourceBounds, [System.Drawing.GraphicsUnit]::Pixel)
  $graphics.Dispose()
  return $bitmap
}

function Save-Png {
  param([string] $RelativePath, [int] $Size)
  $path = Join-Path $root $RelativePath
  [System.IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
  $bitmap = New-LauncherBitmap $Size
  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
}

function Save-Ico {
  param([string] $RelativePath)
  $sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
  $streams = [System.Collections.Generic.List[byte[]]]::new()
  foreach ($size in $sizes) {
    $bitmap = New-LauncherBitmap $size
    $stream = [System.IO.MemoryStream]::new()
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $streams.Add($stream.ToArray())
    $stream.Dispose()
    $bitmap.Dispose()
  }

  $path = Join-Path $root $RelativePath
  [System.IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
  $writer = [System.IO.BinaryWriter]::new([System.IO.File]::Open($path, [System.IO.FileMode]::Create))
  $writer.Write([UInt16]0); $writer.Write([UInt16]1); $writer.Write([UInt16]$sizes.Count)
  $offset = 6 + 16 * $sizes.Count
  for ($i = 0; $i -lt $sizes.Count; $i++) {
    $size = $sizes[$i]; $data = $streams[$i]
    $writer.Write([byte]$(if ($size -eq 256) { 0 } else { $size }))
    $writer.Write([byte]$(if ($size -eq 256) { 0 } else { $size }))
    $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([UInt16]1); $writer.Write([UInt16]32)
    $writer.Write([UInt32]$data.Length); $writer.Write([UInt32]$offset)
    $offset += $data.Length
  }
  foreach ($data in $streams) { $writer.Write($data) }
  $writer.Dispose()
}

# Android launcher densities. The adaptive-icon resource is intentionally not used.
@{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }.GetEnumerator() | ForEach-Object {
  Save-Png "android/app/src/main/res/mipmap-$($_.Key)/ic_launcher.png" $_.Value
}

# Shared master used by Linux, plus web and Windows icons.
Save-Png 'assets/icons/app_icon.png' 1024
Save-Png 'web/favicon.png' 32
Save-Png 'web/icons/Icon-192.png' 192
Save-Png 'web/icons/Icon-512.png' 512
Save-Png 'web/icons/Icon-maskable-192.png' 192
Save-Png 'web/icons/Icon-maskable-512.png' 512
Save-Ico 'windows/runner/resources/app_icon.ico'

# Apple icon catalogs.
@{ 'app_icon_16.png' = 16; 'app_icon_32.png' = 32; 'app_icon_64.png' = 64; 'app_icon_128.png' = 128; 'app_icon_256.png' = 256; 'app_icon_512.png' = 512; 'app_icon_1024.png' = 1024 }.GetEnumerator() | ForEach-Object {
  Save-Png "macos/Runner/Assets.xcassets/AppIcon.appiconset/$($_.Key)" $_.Value
}
@{ 'Icon-App-20x20@1x.png' = 20; 'Icon-App-20x20@2x.png' = 40; 'Icon-App-20x20@3x.png' = 60; 'Icon-App-29x29@1x.png' = 29; 'Icon-App-29x29@2x.png' = 58; 'Icon-App-29x29@3x.png' = 87; 'Icon-App-40x40@1x.png' = 40; 'Icon-App-40x40@2x.png' = 80; 'Icon-App-40x40@3x.png' = 120; 'Icon-App-60x60@2x.png' = 120; 'Icon-App-60x60@3x.png' = 180; 'Icon-App-76x76@1x.png' = 76; 'Icon-App-76x76@2x.png' = 152; 'Icon-App-83.5x83.5@2x.png' = 167; 'Icon-App-1024x1024@1x.png' = 1024 }.GetEnumerator() | ForEach-Object {
  Save-Png "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($_.Key)" $_.Value
}

$source.Dispose()
Write-Output 'Launcher icon assets generated.'
