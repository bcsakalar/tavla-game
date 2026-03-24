#!/bin/bash
# ============================================================
# Tavla Online — Local Development Build/Run
# Overrides production defaults with localhost URLs
# ============================================================

DEV_URL="http://localhost:3006"

echo "Running Tavla Online (Development)..."
echo "API URL: $DEV_URL"
echo "Socket URL: $DEV_URL"
echo ""

flutter run \
  --dart-define=API_BASE_URL=$DEV_URL \
  --dart-define=SOCKET_URL=$DEV_URL
