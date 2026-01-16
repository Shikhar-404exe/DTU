#!/bin/bash
# Install Offline PhotoMath Dependencies
# Run this script to install all required packages

echo "🔧 Installing Offline PhotoMath Dependencies..."
echo ""

# Check if Python is installed
if command -v python3 &> /dev/null; then
    echo "✓ Python found: $(python3 --version)"
elif command -v python &> /dev/null; then
    echo "✓ Python found: $(python --version)"
else
    echo "✗ Python not found. Please install Python first."
    exit 1
fi

# Install Python packages
echo ""
echo "📦 Installing Python packages..."

packages=("pytesseract" "sympy" "numpy" "opencv-python" "Pillow")

for package in "${packages[@]}"; do
    echo "  Installing $package..."
    pip3 install $package --quiet || pip install $package --quiet
    if [ $? -eq 0 ]; then
        echo "  ✓ $package installed"
    else
        echo "  ✗ $package failed"
    fi
done

echo ""
echo "📥 Tesseract OCR Installation"
echo ""

# Check OS and provide instructions
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Linux detected"
    echo "Installing Tesseract OCR..."
    sudo apt-get update
    sudo apt-get install -y tesseract-ocr
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected"
    if command -v brew &> /dev/null; then
        echo "Installing Tesseract OCR via Homebrew..."
        brew install tesseract
    else
        echo "Please install Homebrew first: https://brew.sh"
    fi
else
    echo "Please install Tesseract manually for your OS"
fi

# Check if Tesseract is installed
if command -v tesseract &> /dev/null; then
    echo "✓ Tesseract found: $(tesseract --version | head -n 1)"
else
    echo "⚠ Tesseract not found. Please install it manually."
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Start backend: cd backend && python main.py"
echo "  2. Run Flutter: flutter run"
echo "  3. Test PhotoMath feature"
echo ""
