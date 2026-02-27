#!/bin/bash
# Check if the Windows-to-WSL2 screenshot monitor is running

if pgrep -f "auto-clipboard-monitor" > /dev/null 2>&1; then
    echo "✅ Screenshot automation is running"
    echo "📁 Saves to: $HOME/.screenshots/"
    echo ""
    echo "📋 Recent log:"
    tail -5 "$HOME/.screenshots/monitor.log" 2>/dev/null
else
    echo "❌ Screenshot automation not running"
    echo "💡 Start with: ./start.sh"
fi
