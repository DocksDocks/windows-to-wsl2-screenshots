#!/bin/bash
# Check if the Windows-to-WSL2 screenshot monitor is running

# Use string concatenation so this query doesn't match its own process
result=$(powershell.exe -Command "\$p = 'auto-clipboard-' + 'monitor'; Get-WmiObject Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { \$_.CommandLine -like \"*\$p*\" -and \$_.ProcessId -ne \$PID } | Select-Object ProcessId" 2>/dev/null)

if echo "$result" | grep -q "[0-9]"; then
    echo "✅ Screenshot automation is running"
    echo "📁 Saves to: $HOME/.screenshots/"
    echo ""
    echo "📋 Recent log:"
    tail -5 "$HOME/.screenshots/monitor.log" 2>/dev/null
else
    echo "❌ Screenshot automation not running"
    echo "💡 Start with: ./start.sh"
fi
