#!/usr/bin/env python3
"""
Convert PNG images to WebP format for Flutter app optimization.
Optimized for different image types: backgrounds, genre icons, logos.
"""

import os
import sys
from pathlib import Path
from PIL import Image

def get_image_type(filename: str):
    """Determine image type based on filename."""
    if filename.startswith('bg-'):
        return 'background'
    elif 'logo' in filename.lower() or 'icon' in filename.lower():
        return 'logo'
    elif filename.startswith('default-pic-'):
        return 'avatar'
    elif 'tmdb' in filename.lower():
        return 'logo'
    else:
        return 'genre'

def convert_png_to_webp(input_path: Path, output_path: Path):
    """Convert PNG to WebP with optimization based on image type."""
    img_type = get_image_type(input_path.name)
    
    try:
        img = Image.open(input_path)
        original_width, original_height = img.size
        
        # Settings based on image type
        if img_type == 'background':
            # Background images: high quality, no resizing, lossy compression
            quality = 90
            resize = False
            lossless = False
            max_dimension = None
        elif img_type == 'logo':
            # Logos: medium quality, resize if too large, lossy compression
            quality = 85
            resize = True
            lossless = False
            max_dimension = 512
        elif img_type == 'avatar':
            # Avatars: medium quality, resize if needed
            quality = 80
            resize = True
            lossless = False
            max_dimension = 256
        else:  # genre icons
            # Genre icons: good quality, resize to reasonable size
            quality = 80
            resize = True
            lossless = False
            max_dimension = 512
        
        # Handle alpha channel
        if img.mode == 'RGBA':
            # Check if alpha channel is actually used (not fully opaque)
            alpha = img.getchannel('A')
            if alpha.getextrema() == (255, 255):
                # Alpha is fully opaque, convert to RGB (smaller file)
                img = img.convert('RGB')
            else:
                # Keep RGBA for transparency
                pass
        
        # Resize if needed
        if resize and max_dimension and max(img.size) > max_dimension:
            ratio = max_dimension / max(img.size)
            new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Save as WebP
        save_params = {
            'quality': quality,
            'method': 6,  # slower but better compression
        }
        if lossless:
            save_params['lossless'] = True
        
        img.save(output_path, 'WEBP', **save_params)
        
        original_size = input_path.stat().st_size
        new_size = output_path.stat().st_size
        reduction = (1 - new_size / original_size) * 100
        
        print(f"[OK] {input_path.name}: {original_width}x{original_height} {original_size / 1024:.1f} KB -> {new_size / 1024:.1f} KB ({reduction:.1f}% reduction)")
        return True
        
    except Exception as e:
        print(f"[ERROR] Error converting {input_path.name}: {e}")
        return False

def main():
    image_dir = Path("assets/images")
    if not image_dir.exists():
        print(f"Error: Directory {image_dir} not found")
        sys.exit(1)
    
    # Find all PNG files
    png_files = list(image_dir.glob("*.png"))
    if not png_files:
        print("No PNG files found")
        sys.exit(0)
    
    print(f"Found {len(png_files)} PNG files")
    print("Converting to WebP with optimized settings...")
    
    converted = 0
    failed = 0
    total_original_size = 0
    total_new_size = 0
    
    for png_path in png_files:
        webp_path = png_path.with_suffix('.webp')
        
        original_size = png_path.stat().st_size
        total_original_size += original_size
        
        if convert_png_to_webp(png_path, webp_path):
            converted += 1
            total_new_size += webp_path.stat().st_size
        else:
            failed += 1
    
    # Summary
    print("\n" + "="*50)
    print("CONVERSION SUMMARY")
    print("="*50)
    print(f"Total PNG files: {len(png_files)}")
    print(f"Successfully converted: {converted}")
    print(f"Failed: {failed}")
    print(f"\nOriginal total size: {total_original_size / (1024*1024):.2f} MB")
    print(f"New total size: {total_new_size / (1024*1024):.2f} MB")
    
    if total_original_size > 0:
        total_reduction = (1 - total_new_size / total_original_size) * 100
        print(f"Total reduction: {total_reduction:.1f}%")
    
    print("\nNext steps:")
    print("1. Update image references in Dart files to use .webp extension")
    print("2. Update pubspec.yaml assets section to include .webp files")
    print("3. Test the app to ensure images look good")
    print("4. Consider deleting original .png files after verification")

if __name__ == "__main__":
    # Check if Pillow is installed
    try:
        from PIL import Image
    except ImportError:
        print("Error: Pillow library is required.")
        print("Install it with: pip install Pillow")
        sys.exit(1)
    
    main()