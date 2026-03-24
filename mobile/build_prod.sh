#!/bin/bash
# ============================================================
# Tavla Online — Production APK Build Script
# Default URLs already point to production in app_config.dart
# This script just builds with explicit flags for clarity
# ============================================================

PROD_URL="https://tavla.berkecansakalar.com"

echo "Building Tavla Online APK (Production)..."
echo "API URL: $PROD_URL"
echo "Socket URL: $PROD_URL"
echo ""

flutter build apk --release \
  --dart-define=API_BASE_URL=$PROD_URL \
  --dart-define=SOCKET_URL=$PROD_URL

echo ""
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
