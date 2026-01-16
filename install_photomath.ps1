# Install Offline PhotoMath Dependencies
# Run this script to install all required packages

Write-Host "🔧 Installing Offline PhotoMath Dependencies..." -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found. Please install Python first." -ForegroundColor Red
    exit 1
}

# Install Python packages
Write-Host ""
Write-Host "📦 Installing Python packages..." -ForegroundColor Yellow

$packages = @(
    "pytesseract",
    "sympy",
    "numpy",
    "opencv-python",
    "Pillow"
)

foreach ($package in $packages) {
    Write-Host "  Installing $package..." -ForegroundColor Gray
    pip install $package --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $package installed" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $package failed" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📥 Tesseract OCR Installation Required" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tesseract OCR must be installed separately:" -ForegroundColor White
Write-Host ""
Write-Host "Windows:" -ForegroundColor Cyan
Write-Host "  1. Download from: https://github.com/UB-Mannheim/tesseract/wiki" -ForegroundColor White
Write-Host "  2. Run installer (tesseract-ocr-w64-setup-5.x.x.exe)" -ForegroundColor White
Write-Host "  3. Add to PATH: C:\Program Files\Tesseract-OCR" -ForegroundColor White
Write-Host ""
Write-Host "Linux:" -ForegroundColor Cyan
Write-Host "  sudo apt-get install tesseract-ocr" -ForegroundColor White
Write-Host ""
Write-Host "Mac:" -ForegroundColor Cyan
Write-Host "  brew install tesseract" -ForegroundColor White
Write-Host ""

# Check if Tesseract is installed
try {
    $tesseractVersion = tesseract --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Tesseract found: $tesseractVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ Tesseract not found. Please install it manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Start backend: cd backend && python main.py" -ForegroundColor White
Write-Host "  2. Run Flutter: flutter run" -ForegroundColor White
Write-Host "  3. Test PhotoMath feature" -ForegroundColor White
Write-Host ""
