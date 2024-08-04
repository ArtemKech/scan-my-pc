# Define the output path on the Desktop
$desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'))

# Create the PCScan folder on the Desktop
$pcScanFolderPath = $desktopPath + "\PCScan"
if (-not (Test-Path $pcScanFolderPath)) {
    New-Item -ItemType Directory -Path $pcScanFolderPath
}

# Path for system info file inside the PCScan folder
$outputFilePath = $pcScanFolderPath + "\system_info.txt"

# Function to export Chrome or Edge user profile
function Export-BrowserProfile {
    param (
        [string]$browserType, # Type of browser (Chrome or Edge)
        [string]$browserName
    )

    $profilePath = "$env:LOCALAPPDATA\$browserType\User Data\Default"
    $outputProfilePath = $pcScanFolderPath + "\" + $browserName + "_Profile"

    Write-Output "`nChecking for $browserType profile at path: $profilePath"

    # Check if the profile directory exists and copy it to the PCScan folder
    if (Test-Path $profilePath) {
        Copy-Item -Path $profilePath -Destination $outputProfilePath -Recurse -ErrorAction Stop
        Write-Output "`n$browserName profile has been copied to the PCScan folder"
    }
    else {
        Write-Output "`n$browserName profile not found at path: $profilePath"
    }
}

# Function to export Firefox profile
function Export-FirefoxProfile {
    $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    $profiles = Get-ChildItem -Path $firefoxProfilesPath -Directory

    if ($profiles.Count -eq 0) {
        Write-Output "No Firefox profiles found."
        return
    }

    foreach ($profile in $profiles) {
        $profilePath = $profile.FullName
        if (Test-Path "$profilePath\places.sqlite") {
            $outputFirefoxProfile = "$pcScanFolderPath\Firefox_Profile"

            Write-Output "Copying Firefox profile from path: $profilePath`n"

            Copy-Item -Path $profilePath -Destination $outputFirefoxProfile -Recurse -ErrorAction Stop
            Write-Output "Firefox profile has been copied to the PCScan folder at $outputFirefoxProfile`n"
            return
        }
    }

    Write-Output "No valid Firefox profile found with places.sqlite`n"
}

# Define ASCII art text
$asciiArt = @"

  ooooooo8    oooooooo8     o      oooo   oooo         oooo     oooo ooooo  oooo         oooooooooo    oooooooo8 
888         o888     88    888      8888o  88           8888o   888    888  88            888    888 o888     88 
 888oooooo  888           8  88     88 888o88           88 888o8 88      888              888oooo88  888         
        888 888o     oo  8oooo88    88   8888           88  888  88      888              888        888o     oo 
o88oooo888   888oooo88 o88o  o888o o88o    88          o88o  8  o88o    o888o            o888o        888oooo88   
"@

$githubText = @"

    GitHub: ArtemKech
    GitHub: DeadDove13

"@

# Display ASCII art in green
Write-Host $asciiArt -ForegroundColor Green
Write-Host $githubText -ForegroundColor White

# Prompt the user to select whether to export all profiles
Write-Output "Do you want to export all browser profiles?"
Write-Output "1 - Yes"
Write-Output "0 - No"

# Read user input
$userChoice = Read-Host "Enter your choice"

# Perform the export based on user choice
try {
    switch ($userChoice) {
        1 {
            Export-Bookmarks -browserType 'Google\Chrome' -browserName 'Chrome'
            Export-Bookmarks -browserType 'Microsoft\Edge' -browserName 'Edge'
            Export-FirefoxProfile
        }
        0 {
            Write-Output "No browser profiles will be exported."
        }
        default {
            Write-Output "Invalid choice. Please run the script again and select a valid option."
        }
    }
}
catch {
    Write-Output "An error occurred: $_"
}

# Initialize the output file with UTF-8 encoding
Set-Content -Path $outputFilePath -Value "" -Encoding UTF8

# Collect and write system information
# PC Info
$hostname = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -replace '^[^\\]*\\', ''
$serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
$os = Get-WmiObject -Class Win32_OperatingSystem
$registeredUser = $os.RegisteredUser
$OSarchitecture = (Get-CimInstance Win32_operatingsystem).OSArchitecture

$output = @"
------------------------------------------------------------
PC Info:
------------------------------------------------------------
Hostname: $hostname
Serial Number: $serialNumber
Operating System: $($os.Caption)
OS Version: $($os.Version)
Build Number: $($os.BuildNumber)
Registered User: $registeredUser
OS Architecture: $OSarchitecture

"@

$output | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

# CPU Info
$cpu = Get-WmiObject Win32_Processor
foreach ($processor in $cpu) {
    $cpuInfo = @"
------------------------------------------------------------
CPU Info:
------------------------------------------------------------
Name: $($processor.Name)
Manufacturer: $($processor.Manufacturer)
Description: $($processor.Description)
Number of Cores: $($processor.NumberOfCores)
Number of Logical Processors: $($processor.NumberOfLogicalProcessors)
Max Clock Speed: $($processor.MaxClockSpeed) MHz

"@
    $cpuInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8
}

# GPU Info
$gpus = Get-CimInstance Win32_VideoController

if($gpus.Name -ilike "*NVIDIA*"){
    $qwMemorySize = (Get-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*" -Name HardwareInformation.qwMemorySize -ErrorAction SilentlyContinue)."HardwareInformation.qwMemorySize"
}
elseif($gpus.Name -ilike "*Intel*"){
    $qwMemorySize = ($gpus).AdapterRam
}

$VRAM = [math]::round($qwMemorySize / 1GB)

foreach ($gpu in $gpus) {
    $gpuInfo = @"
------------------------------------------------------------
GPU Info:
------------------------------------------------------------
Manufacturer: $($gpu.AdapterCompatibility)
Model: $($gpu.Name)
VRAM: $VRAM GB

"@
    $gpuInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8
}

# Motherboard Info
$motherboard = Get-WmiObject Win32_BaseBoard
$motherboardInfo = @"
------------------------------------------------------------
Motherboard Info:
------------------------------------------------------------
Manufacturer: $($motherboard.Manufacturer)
Model: $($motherboard.Product)
Serial Number: $($motherboard.SerialNumber)
Version: $($motherboard.Version)

"@
$motherboardInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

# Storage Info
$diskDrives = Get-WmiObject Win32_DiskDrive
$storageInfo = @"
------------------------------------------------------------
Storage Info:
------------------------------------------------------------

"@
foreach ($disk in $diskDrives) {
    $storageInfo += @"
Model: $($disk.Model)
Size: $([math]::round($disk.Size / 1GB, 2)) GB
Serial Number: $($disk.SerialNumber)
Interface Type: $($disk.InterfaceType)

"@
}
$storageInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

# RAM Info
$ramModules = Get-WmiObject Win32_PhysicalMemory
$totalCapacity = 0
foreach ($module in $ramModules) {
    $totalCapacity += $module.Capacity
}
$totalCapacityGB = [math]::round($totalCapacity / 1GB, 2)
$firstModule = $ramModules | Select-Object -First 1
$ramInfo = @"
------------------------------------------------------------
RAM Info:
------------------------------------------------------------
Total Capacity: $totalCapacityGB GB
Speed: $($firstModule.Speed) MHz
Manufacturer: $($firstModule.Manufacturer)
SerialNumber: $($firstModule.SerialNumber)

"@
$ramInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

# USB Devices Info
$deviceCount = 1
$pnpUsbDevices = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' }
foreach ($pnpDevice in $pnpUsbDevices) {
    if ($pnpDevice.PNPClass -ne $null) {
        $deviceInfo = @"
------------------------------------------------------------
USB Device #$deviceCount Info:
------------------------------------------------------------
Name: $($pnpDevice.FriendlyName)
PNPClass: $($pnpDevice.PNPClass)

"@
        $deviceInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8
        $deviceCount++
    }
}

# Mapped Network Drives Info
$mappedDrives = Get-WmiObject -Query "SELECT * FROM Win32_NetworkConnection"

$networkDriveInfo = @"
------------------------------------------------------------
Mapped Network Drives Info:
------------------------------------------------------------

"@
foreach ($drive in $mappedDrives) {
    $networkDriveInfo += @"
Local Name: $($drive.LocalName)
Remote Path: $($drive.RemoteName)
Description: $($drive.Description)
Status: $($drive.Status)

"@
}
$networkDriveInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

# Installed Applications
$appInfo = @"
------------------------------------------------------------
Installed Applications:
------------------------------------------------------------
"@

$appInfo | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

# Installed Applications Collection
$installedApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object { $_.DisplayName } | 
Select-Object @{Name = 'Application'; Expression = { $_.DisplayName } }, @{Name = 'Version'; Expression = { $_.DisplayVersion } }, Publisher

$formattedOutput = $installedApps | Format-Table -Property Application, Version, Publisher -AutoSize | Out-String
$formattedOutput | Out-File -FilePath $outputFilePath -Append -Encoding UTF8

Write-Output "System information and installed applications have been written to $outputFilePath `n"

# Wait for the user to press a key
Read-Host -Prompt "Press Enter to exit"
