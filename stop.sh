#!/bin/bash
# Stop the Windows-to-WSL2 screenshot monitor

echo "🛑 Stopping screenshot automation..."
powershell.exe -Command "Get-WmiObject Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { \$_.CommandLine -like '*auto-clipboard-monitor*' } | ForEach-Object { Stop-Process -Id \$_.ProcessId -Force }" 2>/dev/null
echo "✅ Screenshot automation stopped"
