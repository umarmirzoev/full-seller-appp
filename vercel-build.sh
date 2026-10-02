#!/bin/bash
set -e

echo "== Installing Flutter SDK =="
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter-sdk
export PATH="$PATH:$(pwd)/flutter-sdk/bin"

flutter config --enable-web
flutter pub get

echo "== Building Flutter web (release) =="
flutter build web --release

echo "== Build finished, output at build/web =="
