#!/bin/bash
# Stop the Windows-to-WSL2 screenshot monitor

echo "🛑 Stopping screenshot automation..."
pkill -f "auto-clipboard-monitor" 2>/dev/null || true
echo "✅ Screenshot automation stopped"
