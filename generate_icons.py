#!/usr/bin/env python3
"""Generate Flutter app icons from app logo.png"""
from PIL import Image
import os
import shutil

# Load the source icon
source_icon = Image.open('assets/app logo.png')

# Android icon sizes and paths
android_sizes = {
    'mipmap-ldpi': 36,
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# iOS icon sizes
ios_sizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-50x50@1x.png': 50,
    'Icon-App-50x50@2x.png': 100,
    'Icon-App-57x57@1x.png': 57,
    'Icon-App-57x57@2x.png': 114,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-72x72@1x.png': 72,
    'Icon-App-72x72@2x.png': 144,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

print("🔧 Generating Android icons...")
for dir_name, size in android_sizes.items():
    # Create resized icon
    resized = source_icon.resize((size, size), Image.Resampling.LANCZOS)
    
    # Determine path
    android_path = f'android/app/src/main/res/{dir_name}/ic_launcher.png'
    
    # Create directory if needed
    os.makedirs(os.path.dirname(android_path), exist_ok=True)
    
    # Save icon
    resized.save(android_path, 'PNG')
    print(f"  ✓ Created {dir_name}/ic_launcher.png ({size}x{size})")

print("\n🔧 Generating iOS icons...")
ios_base_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for filename, size in ios_sizes.items():
    # Create resized icon
    resized = source_icon.resize((size, size), Image.Resampling.LANCZOS)
    
    # Create directory if needed
    os.makedirs(ios_base_path, exist_ok=True)
    
    # Save icon
    icon_path = f'{ios_base_path}/{filename}'
    resized.save(icon_path, 'PNG')
    print(f"  ✓ Created {filename} ({size}x{size})")

print("\n✅ Successfully generated all app icons!")
print("Now run: flutter clean && flutter run")
