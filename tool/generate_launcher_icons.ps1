<#!
Generates all platform launcher icon bitmaps from the homepage leaf mark.
Run from the repository root: .\tool\generate_launcher_icons.ps1
#>

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$flutterRoot = if ($env:FLUTTER_ROOT) { $env:FLUTTER_ROOT } else { 'C:\Users\Tamim\flutter' }
$materialFontPath = Join-Path $flutterRoot 'bin\cache\artifacts\material_fonts\materialicons-regular.otf'
if (-not (Test-Path -LiteralPath $materialFontPath)) {
  throw "Material Icons font was not found at $materialFontPath. Set FLUTTER_ROOT before running this script."
}
$materialFonts = [System.Drawing.Text.PrivateFontCollection]::new()
$materialFonts.AddFontFile($materialFontPath)
$materialGlyph = [char]::ConvertFromUtf32(0xF07F8)

function Add-RoundedRectangle {
  param([System.Drawing.Drawing2D.GraphicsPath] $Path, [float] $X, [float] $Y, [float] $Width, [float] $Height, [float] $Radius)
  $diameter = $Radius * 2
  $Path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $Path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $Path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
  $Path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $Path.CloseFigure()
}

function New-LauncherBitmap {
  param([int] $Size, [switch] $ForegroundOnly)
  $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $scale = $Size / 1024.0
  $graphics.ScaleTransform($scale, $scale)

  if (-not $ForegroundOnly) {
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 0, 80, 50))
  }

  $tile = [System.Drawing.Drawing2D.GraphicsPath]::new()
  Add-RoundedRectangle $tile 288 288 448 448 112
  $graphics.FillPath([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 147, 213, 170)), $tile)
  $tile.Dispose()

  $format = [System.Drawing.StringFormat]::new()
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $font = [System.Drawing.Font]::new($materialFonts.Families[0], 280, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $graphics.DrawString($materialGlyph, $font, [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 0, 80, 50)), [System.Drawing.RectangleF]::new(288, 288, 448, 448), $format)
  $font.Dispose()
  $format.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function Save-Png {
  param([string] $RelativePath, [int] $Size, [switch] $ForegroundOnly)
  $path = Join-Path $root $RelativePath
  $directory = Split-Path -Parent $path
  [System.IO.Directory]::CreateDirectory($directory) | Out-Null
  $bitmap = New-LauncherBitmap $Size -ForegroundOnly:$ForegroundOnly
  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
}

function Save-Ico {
  param([string] $RelativePath)
  $sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
  $streams = foreach ($size in $sizes) {
    $bitmap = New-LauncherBitmap $size
    $stream = [System.IO.MemoryStream]::new()
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $stream.ToArray()
  }
  $path = Join-Path $root $RelativePath
  [System.IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
  $writer = [System.IO.BinaryWriter]::new([System.IO.File]::Open($path, [System.IO.FileMode]::Create))
  $writer.Write([UInt16]0); $writer.Write([UInt16]1); $writer.Write([UInt16]$sizes.Count)
  $offset = 6 + 16 * $sizes.Count
  for ($i = 0; $i -lt $sizes.Count; $i++) {
    $size = $sizes[$i]; $data = $streams[$i]
    $writer.Write([byte]($(if ($size -eq 256) { 0 } else { $size })))
    $writer.Write([byte]($(if ($size -eq 256) { 0 } else { $size })))
    $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([UInt16]1); $writer.Write([UInt16]32)
    $writer.Write([UInt32]$data.Length); $writer.Write([UInt32]$offset)
    $offset += $data.Length
  }
  foreach ($data in $streams) { $writer.Write($data) }
  $writer.Dispose()
}

# A project-local 1024px master PNG, plus Android legacy and adaptive assets.
Save-Png 'assets/icons/app_icon.png' 1024
Save-Png 'android/app/src/main/res/drawable/ic_launcher_foreground.png' 432 -ForegroundOnly
@{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }.GetEnumerator() | ForEach-Object {
  Save-Png "android/app/src/main/res/mipmap-$($_.Key)/ic_launcher.png" $_.Value
}

# Web/PWA and Windows.
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

Write-Output 'Launcher icon assets generated.'
