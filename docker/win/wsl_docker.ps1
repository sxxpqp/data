# WSL & Docker Repair Script
# This script checks and repairs WSL, then ensures Docker is running

# Set error handling
$ErrorActionPreference = "Stop"

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "===== WSL & DOCKER REPAIR SCRIPT =====" -ForegroundColor Green
Write-Host "Path: $scriptPath" -ForegroundColor Cyan

# Set path variables
$wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdateFile = "$env:TEMP\wsl_update_x64.msi"

# Function to check if WSL is installed
function Test-WSLInstalled {
    try {
        $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
        if ($wslCommand) {
            # Test if WSL is actually working
            $output = wsl --status 2>&1
            if ($output -match "not installed") {
                return $false
            }
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# Function to install WSL
function Install-WSL {
    Write-Host "`nWSL is not installed. Installing WSL..." -ForegroundColor Yellow
    
    try {
        # First try the simple install command
        Write-Host "Attempting simple WSL installation..." -ForegroundColor Yellow
        wsl --install 2>&1 | Out-Null
        
        # Check if it seemed to work
        if (Test-WSLInstalled) {
            Write-Host "WSL installed successfully with simple method." -ForegroundColor Green
            return $true
        }
        
        # If simple install failed, try more advanced approach
        Write-Host "Simple install may have failed, trying advanced method..." -ForegroundColor Yellow
        
        # Enable required Windows features
        Write-Host "Enabling Windows Subsystem for Linux feature..." -ForegroundColor Yellow
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        
        Write-Host "Enabling Virtual Machine Platform feature..." -ForegroundColor Yellow
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        
        # Download and install WSL2 update package
        Write-Host "Downloading WSL2 update package..." -ForegroundColor Yellow
        if (-not (Test-Path $wslUpdateFile)) {
            Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdateFile -UseBasicParsing
        }
        
        Write-Host "Installing WSL2 update package..." -ForegroundColor Yellow
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$wslUpdateFile`" /quiet" -Wait
        
        # Set WSL2 as default
        Write-Host "Setting WSL2 as default..." -ForegroundColor Yellow
        wsl --set-default-version 2
        
        Write-Host "WSL has been installed but may require a system restart." -ForegroundColor Yellow
        $restart = Read-Host "Would you like to restart your computer now? (Y/N)"
        if ($restart -eq "Y" -or $restart -eq "y") {
            Write-Host "Restarting computer. Run this script again after restart." -ForegroundColor Cyan
            Start-Sleep -Seconds 3
            Restart-Computer -Force
            exit
        } else {
            Write-Host "You may need to restart your computer for WSL to work properly." -ForegroundColor Yellow
            Write-Host "We'll try to continue anyway..." -ForegroundColor Yellow
        }
        
        return $true
    } catch {
        Write-Host "WSL installation failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to repair WSL issues
function Repair-WSL {
    Write-Host "`nAttempting to repair WSL issues..." -ForegroundColor Yellow
    
    # Install WSL if not installed
    if (-not (Test-WSLInstalled)) {
        $result = Install-WSL
        if (-not $result) {
            Write-Host "Failed to install WSL." -ForegroundColor Red
            return $false
        }
    }
    
    # Shutdown any running WSL instances
    Write-Host "Shutting down any running WSL instances..." -ForegroundColor Yellow
    try {
        wsl --shutdown 2>$null
    } catch {
        # Ignore errors here
    }
    
    # Update WSL kernel
    Write-Host "Updating WSL2 kernel..." -ForegroundColor Yellow
    try {
        # Download and install the WSL update package if it's not already there
        if (-not (Test-Path $wslUpdateFile)) {
            Write-Host "Downloading WSL2 update package..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdateFile -UseBasicParsing
        }
        
        Write-Host "Installing WSL2 update package..." -ForegroundColor Yellow
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$wslUpdateFile`" /quiet" -Wait
        
        # Try to update WSL through command line
        Write-Host "Running WSL update command..." -ForegroundColor Yellow
        wsl --update --web-download 2>$null
        
        # Set WSL2 as default version
        wsl --set-default-version 2 2>$null
        
        Write-Host "WSL repair completed." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "WSL repair encountered issues, but we'll continue: $_" -ForegroundColor Yellow
        return $false
    }
}

# STEP 1: Check Docker installation
try {
    Get-Command docker -ErrorAction Stop | Out-Null
    Write-Host "Docker is installed." -ForegroundColor Green
} catch {
    Write-Host "Docker is not installed. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    pause
    exit 1
}

# STEP 2: Check and repair WSL before starting Docker
Write-Host "Checking if WSL is properly installed..." -ForegroundColor Yellow
if (-not (Test-WSLInstalled)) {
    Write-Host "WSL is not properly installed. This is needed for Docker to work correctly." -ForegroundColor Yellow
    Write-Host "Attempting to install and configure WSL..." -ForegroundColor Yellow
    $wslResult = Install-WSL
    if (-not $wslResult) {
        Write-Host "WARNING: WSL setup had issues. Docker might not work properly." -ForegroundColor Red
    }
}

# STEP 3: Start Docker and attempt to fix if it doesn't start
Write-Host "Attempting to start Docker..." -ForegroundColor Yellow

# First try - simply start Docker and wait
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue

# Wait for Docker to start - first attempt
Write-Host "Waiting for Docker to start (this may take a few minutes)..." -ForegroundColor Yellow
$initialAttempts = 12  # 1 minute wait initially
$attempts = 0
$dockerRunning = $false

while ($attempts -lt $initialAttempts) {
    Write-Host "Checking Docker status (attempt $($attempts+1) of $initialAttempts)..." -ForegroundColor Yellow
    try {
        docker info | Out-Null
        $dockerRunning = $true
        Write-Host "Docker is now running!" -ForegroundColor Green
        break
    } catch {
        Start-Sleep -Seconds 5
        $attempts++
    }
}

# If Docker didn't start, try to repair WSL
if (-not $dockerRunning) {
    Write-Host "Docker is not starting normally. This could be due to WSL issues." -ForegroundColor Yellow
    
    # Ask if we should try to repair
    $repair = Read-Host "Would you like to attempt to repair WSL which Docker depends on? (Y/N)"
    
    if ($repair -eq "Y" -or $repair -eq "y") {
        # Kill any Docker processes first
        Write-Host "Stopping any running Docker processes..." -ForegroundColor Yellow
        Get-Process | Where-Object { $_.Name -like "*docker*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # Repair WSL
        $repairResult = Repair-WSL
        
        # Try to start Docker again
        Write-Host "Starting Docker again after WSL repair..." -ForegroundColor Yellow
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
        
        # Wait longer this time
        Write-Host "Giving Docker more time to start after repairs..." -ForegroundColor Yellow
        $maxAttempts = 24  # 2 minutes wait after repair
        $attempts = 0
        
        while ($attempts -lt $maxAttempts) {
            Write-Host "Checking Docker status after repair (attempt $($attempts+1) of $maxAttempts)..." -ForegroundColor Yellow
            try {
                docker info | Out-Null
                $dockerRunning = $true
                Write-Host "Docker is now running after WSL repair!" -ForegroundColor Green
                break
            } catch {
                Start-Sleep -Seconds 5
                $attempts++
            }
        }
    }
}

# Final check - if Docker still isn't running
if (-not $dockerRunning) {
    Write-Host "`nDocker failed to start even after repair attempts." -ForegroundColor Red
    Write-Host "This may require a system restart." -ForegroundColor Yellow
    
    $restart = Read-Host "Would you like to restart your computer now? (Y/N)"
    if ($restart -eq "Y" -or $restart -eq "y") {
        Write-Host "Restarting computer. Please run this script again after restart." -ForegroundColor Cyan
        Start-Sleep -Seconds 3
        Restart-Computer -Force
        exit
    } else {
        Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
        Write-Host "1. Make sure virtualization is enabled in BIOS" -ForegroundColor White
        Write-Host "2. Manually restart and run this script again" -ForegroundColor White
        Write-Host "3. Try installing Docker Desktop fresh" -ForegroundColor White
        pause
        exit 1
    }
}

Write-Host "===== WSL & DOCKER CHECK COMPLETE =====" -ForegroundColor Green
Write-Host "Docker is running successfully. You can now use Docker commands." -ForegroundColor Cyan
pause