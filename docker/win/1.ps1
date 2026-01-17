 # N8N Installer Script with WSL & Docker Repair
# This script installs n8n with Docker and automatically fixes WSL issues

# Set error handling
$ErrorActionPreference = "Stop"

# Get script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "===== N8N INSTALLATION SCRIPT =====" -ForegroundColor Green
Write-Host "Path: $scriptPath" -ForegroundColor Cyan

# Set path variables
$tarPath = Join-Path $scriptPath "n8n-custom.tar"
$containerDataPath = Join-Path $scriptPath "container-data"
$dockerDataPath = "C:\Users\$env:USERNAME\.docker"
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
    Write-Host "\nWSL is not installed. Installing WSL..." -ForegroundColor Yellow
    
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
    Write-Host "\nAttempting to repair WSL issues..." -ForegroundColor Yellow
    
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
    Write-Host "\nDocker failed to start even after repair attempts." -ForegroundColor Red
    Write-Host "This may require a system restart." -ForegroundColor Yellow
    
    $restart = Read-Host "Would you like to restart your computer now? (Y/N)"
    if ($restart -eq "Y" -or $restart -eq "y") {
        Write-Host "Restarting computer. Please run this script again after restart." -ForegroundColor Cyan
        Start-Sleep -Seconds 3
        Restart-Computer -Force
        exit
    } else {
        Write-Host "\nTroubleshooting tips:" -ForegroundColor Yellow
        Write-Host "1. Make sure virtualization is enabled in BIOS" -ForegroundColor White
        Write-Host "2. Manually restart and run this script again" -ForegroundColor White
        Write-Host "3. Try installing Docker Desktop fresh" -ForegroundColor White
        pause
        exit 1
    }
}

# STEP 4: Check for required files
if (-not (Test-Path $tarPath)) {
    Write-Host "Error: Docker image file not found: $tarPath" -ForegroundColor Red
    pause
    exit 1
}

if (-not (Test-Path $containerDataPath)) {
    Write-Host "Error: Container data directory not found: $containerDataPath" -ForegroundColor Red
    pause
    exit 1
}

# STEP 5: Import Docker image
Write-Host "Importing Docker image..." -ForegroundColor Yellow
$tarFileSize = (Get-Item $tarPath).Length / 1MB # 鑾¸ˆà¸ˆ?峰彇?鏂?囦?欢?澶у皬锛?圡MB锛??Write-Host "The image file (n8n-custom.tar) is approximately $($tarFileSize.ToString('F2')) MB." -ForegroundColor Cyan
Write-Host "This step can take a significant amount of time depending on the image size and your system's performance." -ForegroundColor Yellow
Write-Host "Please be patient and do not close this window. The script is working..." -ForegroundColor Yellow
# Dynamically capture the loaded image name
$loadImageOutput = docker load -i $tarPath
$imageName = ($loadImageOutput | Select-String -Pattern "Loaded image:" | ForEach-Object { $_.Line.Split(' ')[-1] })

if (-not $imageName) {
    Write-Host "FATAL: Could not determine the name of the loaded image from the .tar file." -ForegroundColor Red
    Write-Host "Docker load output: $loadImageOutput" -ForegroundColor Yellow
    pause
    exit 1
}
Write-Host "Docker image '$imageName' imported successfully!" -ForegroundColor Green

# STEP 6: Create data directory
Write-Host "Creating data directory: $dockerDataPath" -ForegroundColor Yellow
New-Item -Path $dockerDataPath -ItemType Directory -Force | Out-Null
Write-Host "Data directory created!" -ForegroundColor Green

# STEP 7: Copy container data
Write-Host "Copying container data..." -ForegroundColor Yellow
robocopy $containerDataPath $dockerDataPath /MIR /R:1 /W:1
Write-Host "Data copy complete!" -ForegroundColor Green

# STEP 8: Remove existing container if present
$existingContainer = docker ps -a --filter "name=n8n-custom" --format "{{.Names}}" 2>$null
if ($existingContainer -eq "n8n-custom") {
    Write-Host "Removing existing n8n-custom container..." -ForegroundColor Yellow
    docker stop n8n-custom 2>$null
    docker rm n8n-custom 2>$null
    Write-Host "Existing container removed!" -ForegroundColor Green
}

# STEP 9: Start new container using the dynamically found image name
Write-Host "Starting n8n container using image: $imageName" -ForegroundColor Yellow
docker run -d --name n8n-custom -p 5678:5678 -v "${dockerDataPath}:/data" --restart=unless-stopped $imageName
Write-Host "n8n container started!" -ForegroundColor Green

# STEP 10: Wait briefly and open browser
Write-Host "Waiting for n8n to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "Opening browser..." -ForegroundColor Green
Start-Process "http://localhost:5678"

Write-Host "===== INSTALLATION COMPLETE! =====" -ForegroundColor Green
Write-Host "n8n is now open in your browser at: http://localhost:5678" -ForegroundColor Cyan
Write-Host "If the interface is not loaded yet, wait a few seconds and refresh." -ForegroundColor Cyan
pause
 
