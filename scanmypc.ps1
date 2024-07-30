
$text = @"
          
          
                                                                                                               
 oooooooo8    oooooooo8     o      oooo   oooo         oooo     oooo ooooo  oooo         oooooooooo    oooooooo8 
888         o888     88    888      8888o  88           8888o   888    888  88            888    888 o888     88 
 888oooooo  888           8  88     88 888o88           88 888o8 88      888              888oooo88  888         
        888 888o     oo  8oooo88    88   8888           88  888  88      888              888        888o     oo 
o88oooo888   888oooo88 o88o  o888o o88o    88          o88o  8  o88o    o888o            o888o        888oooo88  



                                            GitHub: ArtemKech                                                                                                                                                                                                                              
 
                                                                                                         
"@

function Show-TypingText {
    param (
        [string]$text,
        [int]$delay = 50
    )
    
    foreach ($char in $text.ToCharArray()) {
        Write-Host -NoNewline $char
        Start-Sleep -Milliseconds $delay
    }
    Write-Host
}

Show-TypingText -text $text -delay 0.2

$hostname = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$hostname = $hostname -creplace '^[^\\]*\\', ''
$desktopPath = [Environment]::GetFolderPath("Desktop")
$outputFile = "$desktopPath\system_info.txt"

# Cleans file before running
Set-Content -Path $outputFile -Value ""

# Initializes the output file
"" | Out-File -FilePath $outputFile

# Get Serial Number
$serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber

# Get Operating System Information
$os = Get-WmiObject -Class Win32_OperatingSystem

# Get Registered User
$registeredUser = $os.RegisteredUser

# Get OS Architecture
$OSarchitecture = (Get-CimInstance Win32_operatingsystem).OSArchitecture

# Create a string with the information
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

# Output the information to the file
$output | Out-File -FilePath $outputFile -Append

# Retrieves CPU information using WMI
$cpu = Get-WmiObject Win32_Processor
$cpuInfo = ""
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
    $cpuInfo | Out-File -FilePath $outputFile -Append
}                                            

# Retrieves and writes GPU info
$gpus = Get-CimInstance Win32_VideoController
foreach ($gpu in $gpus) {
$VRAM = [math]::round($qwMemorySize/1GB, 3)
$gpuInfo = @"
------------------------------------------------------------
GPU Info:
------------------------------------------------------------
Manufacturer: $($gpu.AdapterCompatibility)
Model: $($gpu.Name)
VRAM: $VRAM GB


"@
   $gpuInfo | Out-File -FilePath $outputFile -Append
}                                                                                               
                                                                                              
# Retrieve motherboard information using WMI
$motherboard = Get-WmiObject Win32_BaseBoard

# Display motherboard information
$motherboardInfo = @"
------------------------------------------------------------
Motherboard Info:
------------------------------------------------------------
Manufacturer: $($motherboard.Manufacturer)
Model: $($motherboard.Product)
Serial Number: $($motherboard.SerialNumber)
Version: $($motherboard.Version)


"@

$motherboardInfo | Out-File -FilePath $outputFile -Append

# Retrieve storage information using WMI
$diskDrives = Get-WmiObject Win32_DiskDrive

# Create a string to store the storage info
$storageInfo = @"
------------------------------------------------------------
Storage Info:
------------------------------------------------------------
"@

# Loop through each disk drive and collect details
foreach ($disk in $diskDrives) {
    $storageInfo += @"

Model: $($disk.Model)
Size: $([math]::round($disk.Size / 1GB, 2)) GB
Serial Number: $($disk.SerialNumber)
Interface Type: $($disk.InterfaceType)


"@
}

$storageInfo | Out-File -FilePath $outputFile -Append                        

# Retrieves RAM information using WMI
$ramModules = Get-WmiObject Win32_PhysicalMemory

# Initializes total capacity variable
$totalCapacity = 0

# Loops through each RAM module and accumulate the total capacity
foreach ($module in $ramModules) {
    $totalCapacity += $module.Capacity
}

# Converts total capacity to GB and rounds it
$totalCapacityGB = [math]::round($totalCapacity / 1GB, 2)


# Additional information from the first RAM module
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

$ramInfo | Out-File -FilePath $outputFile -Append

# Initializes USB device count
$deviceCount = 1

# Retrieves and filters USB devices
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
        $deviceInfo | Out-File -FilePath $outputFile -Append
        $deviceCount++
    }
}


Write-Output "Information collected and saved to $outputFile"
