#!/bin/bash

# Ralph-CoS App Icon Generator
# Converts app_icon.svg to all required Android launcher icon sizes

echo "🛡️  Ralph-CoS Icon Generator"
echo "=============================="
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick is not installed."
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    echo ""
    exit 1
fi

# Check if SVG file exists
if [ ! -f "assets/logo/app_icon.svg" ]; then
    echo "❌ app_icon.svg not found at assets/logo/app_icon.svg"
    exit 1
fi

echo "✅ Found app_icon.svg"
echo ""

# Create output directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

echo "📁 Creating mipmap directories..."
echo ""

# Function to generate icon
generate_icon() {
    local size=$1
    local density=$2
    local output="android/app/src/main/res/mipmap-${density}/ic_launcher.png"

    echo "🎨 Generating ${density} (${size}x${size})..."
    convert -background none -resize ${size}x${size} \
        assets/logo/app_icon.svg "$output"

    if [ $? -eq 0 ]; then
        echo "   ✅ Created: $output"
    else
        echo "   ❌ Failed: $output"
    fi
}

# Generate all icon sizes
generate_icon 48 "mdpi"
generate_icon 72 "hdpi"
generate_icon 96 "xhdpi"
generate_icon 144 "xxhdpi"
generate_icon 192 "xxxhdpi"

echo ""
echo "=============================="
echo "✅ Icon generation complete!"
echo ""
echo "Next steps:"
echo "1. Review generated icons in android/app/src/main/res/mipmap-*/"
echo "2. Rebuild app: flutter build apk --release"
echo "3. Install: adb install build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "🛡️  Your app now has its identity!"
