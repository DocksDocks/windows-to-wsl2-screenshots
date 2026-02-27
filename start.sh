#!/bin/bash
# Start the Windows-to-WSL2 screenshot monitor

echo "🚀 Starting Windows-to-WSL2 screenshot automation..."

pkill -f "auto-clipboard-monitor" 2>/dev/null || true

mkdir -p "$HOME/.screenshots"

script_dir="$(dirname "$(realpath "$0")")"
ps_script="$script_dir/auto-clipboard-monitor.ps1"

if [ ! -f "$ps_script" ]; then
    echo "❌ PowerShell script not found at: $ps_script"
    exit 1
fi

nohup powershell.exe -ExecutionPolicy Bypass -File "$ps_script" < /dev/null > "$HOME/.screenshots/monitor.log" 2>&1 9>&- &

echo "✅ SCREENSHOT AUTOMATION IS NOW RUNNING!"
echo ""
echo "🔥 Take a screenshot (Win+Shift+S) → path auto-copied to clipboard → Ctrl+V!"
echo "📁 Images save to: $HOME/.screenshots/"
