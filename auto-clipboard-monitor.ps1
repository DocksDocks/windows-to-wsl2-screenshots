# True automatic clipboard monitor using Windows events
param(
    [string]$SaveDirectory = "~/.screenshots",
    [string]$WslDistro = "auto"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Write-Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message"
}

# Convert the tilde path to WSL format
if ($SaveDirectory -eq "~/.screenshots") {
    # Try to auto-detect WSL distribution if auto mode is used
    if ($WslDistro -eq "auto") {
        $WslDistros = @(wsl.exe -l -q | Where-Object { 
            $_ -and $_.Trim() -ne "" -and $_ -notlike "*docker*" 
        } | ForEach-Object { 
            $_.Trim() -replace '\s+', '' -replace '\x00', ''
        })
        if ($WslDistros.Count -gt 0) {
            $WslDistro = $WslDistros[0]
            Write-Log "Auto-detected WSL distribution: $WslDistro"
        }
    }
    
    # Get the actual WSL username instead of Windows username
    $WslUsername = wsl.exe -d $WslDistro -e whoami
    $WslUsername = $WslUsername.Trim()
    $SaveDirectory = "\\wsl.localhost\$WslDistro\home\$WslUsername\.screenshots"
}

if (!(Test-Path $SaveDirectory)) {
    New-Item -ItemType Directory -Path $SaveDirectory -Force | Out-Null
}

Write-Log "WINDOWS-TO-WSL2 SCREENSHOT AUTOMATION STARTED"
Write-Log "Auto-saving images to: $SaveDirectory"
Write-Log "Press Ctrl+C to stop"



Write-Log "Monitoring clipboard events and directory changes..."
$previousHash = $null
$lastFileTime = Get-Date

# Function to copy path to clipboard
function Set-ClipboardPath($path) {
    $maxRetries = 2
    for ($i = 0; $i -lt $maxRetries; $i++) {
        try {
            Set-Clipboard -Value $path
            return $true
        } catch {
            if ($i -eq ($maxRetries - 1)) {
                try {
                    $path | clip.exe
                    return $true
                } catch {
                    Write-Warning "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Could not set clipboard: $_"
                    return $false
                }
            }
            Start-Sleep -Milliseconds 200
        }
    }
    return $false
}

while ($true) {
    try {
        Start-Sleep -Milliseconds 500
        
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            $image = [System.Windows.Forms.Clipboard]::GetImage()
            if ($image) {
                $ms = New-Object System.IO.MemoryStream
                $image.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
                $imageBytes = $ms.ToArray()
                $ms.Dispose()
                $currentHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($imageBytes))
                
                if ($currentHash -ne $previousHash) {
                    Write-Log "New image detected in clipboard"
                    
                    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                    $filename = "screenshot_$timestamp.png"
                    $filepath = Join-Path $SaveDirectory $filename
                    $image.Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)
                    
                    $latestPath = Join-Path $SaveDirectory "latest.png"
                    if (Test-Path $latestPath) { Remove-Item $latestPath -Force }
                    Copy-Item $filepath $latestPath -Force
                    
                    # Create full path for WSL2 instead of using tilde
                    $wslPath = "/home/$WslUsername/.screenshots/$filename"
                    Start-Sleep -Milliseconds 1000
                    
                    if (Set-ClipboardPath $wslPath) {
                        Write-Log "AUTO-SAVED: $filename"
                        Write-Log "Path ready for Ctrl+V: $wslPath"
                    }
                    
                    $previousHash = $currentHash
                }
                $image.Dispose()
            }
        }
        
        # Also check for new files in the directory (for drag-drop screenshots)
        $currentTime = Get-Date
        $newFiles = Get-ChildItem $SaveDirectory -Filter "*.png" | Where-Object { 
            $_.LastWriteTime -gt $lastFileTime -and $_.Name -ne "latest.png" 
        }
        
        if ($newFiles) {
            foreach ($file in $newFiles) {
                # Create full path for WSL2 instead of using tilde
                $wslPath = "/home/$WslUsername/.screenshots/$($file.Name)"
                Copy-Item $file.FullName (Join-Path $SaveDirectory "latest.png") -Force
                
                if (Set-ClipboardPath $wslPath) {
                    Write-Log "NEW FILE DETECTED: $($file.Name)"
                    Write-Log "Path ready for Ctrl+V: $wslPath"
                }
            }
            $lastFileTime = $currentTime
        }
        
    } catch {
        Write-Warning "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Error in main loop: $_"
        Start-Sleep -Milliseconds 1000
    }
}
