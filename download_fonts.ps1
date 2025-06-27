# URLs for Poppins font files
$fonts = @{
    "Poppins-Regular.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf"
    "Poppins-Medium.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf"
    "Poppins-SemiBold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf"
    "Poppins-Bold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
}

# Create fonts directory if it doesn't exist
$fontsDir = "assets/fonts"
if (-not (Test-Path $fontsDir)) {
    New-Item -ItemType Directory -Path $fontsDir -Force
}

# Download each font file
foreach ($font in $fonts.GetEnumerator()) {
    $outputPath = Join-Path $fontsDir $font.Key
    Write-Host "Downloading $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile $outputPath
}

Write-Host "Font files downloaded successfully!" 