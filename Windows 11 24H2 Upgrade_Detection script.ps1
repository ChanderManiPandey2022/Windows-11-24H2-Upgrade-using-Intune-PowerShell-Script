# SYNOPSIS
# Upgrade to Windows 11 24H2 from Windows 10 using Intune and Proactive Remediation.

# DESCRIPTION
# Upgrade to Windows 11 24H2 from Windows 10 using Intune and Proactive Remediation.

# DEMO
# YouTube video link → https://www.youtube.com/@chandermanipandey8763

# NOTES
# Version:         V1.0  
# Author:          Chander Mani Pandey 
# Creation Date:   1 June 2025

# Find the author on: 
 
# YouTube:         https://www.youtube.com/@chandermanipandey8763  
# Twitter:         https://twitter.com/Mani_CMPandey  
# LinkedIn:        https://www.linkedin.com/in/chandermanipandey  
# BlueSky:         https://bsky.app/profile/chandermanipandey.bsky.social
# GitHub:          https://github.com/ChanderManiPandey2022

# Update
# v1.1 ---> Fixed to find the correct os build version  

#========================User Input Section========

$DiskSpace = "45"

#==================================================


$error.clear() ## this is the clear error history 
clear
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Force
$ErrorActionPreference = 'SilentlyContinue'

# Initialize Logging
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Upgrading Windows 10 to Windows 11 24H2 Using Intune Proactive Detection Script $(Get-Date -Format 'yyyy/MM/dd') ==================="

$HostName = hostname
# Check if ESP is running
$ESP = Get-Process -ProcessName CloudExperienceHostBroker -ErrorAction SilentlyContinue
If ($ESP) {
    #Write-Host "Windows Autopilot ESP Running"
    Write-Log "Windows Autopilot ESP Running"
    Exit 1 
     }
Else {
    #Write-Host "Windows Autopilot ESP Not Running"
    Write-Log "Windows Autopilot ESP Not Running"
    
     }

Write-Log "Checking Machine :- $HostName OS Version"
$OSBuild = ([System.Environment]::OSVersion.Version).Build

IF (!($OSBuild)) {
    Write-Log 'Failed to Find Build Info'
    Exit 1
} else{
    Write-Log "Machine :- $HostName OS Version is $OSBuild"
}
$CheckForUpdateA = Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-WindowsUpdateClient/Operational'
 }
$TopA = $CheckForUpdateA | Select-Object -First 1

Write-Log "Last Check for Update date and time is:- $($TopA.TimeCreated)"

#Checking Windows PC Health Check installation status

$AppName = "Windows PC Health Check"

$App = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $AppNmae } 

if ($App.IdentifyingNumber -eq $null)
{
    Write-Log "'$AppName' application not installed"
}
else
{
    Write-Log "'$AppName' application already installed"
}

Write-Log "Checking if the system meets Windows 11 hardware requirements..."

# Check TPM version
$tpmInfo = tpmtool getdeviceinformation
$tpmVersion = ($tpmInfo | Where-Object { $_ -match "TPM Version" }) -replace ".*TPM Version:\s*", ""
if ($tpmVersion) {
    if ($tpmVersion -ge "2.0") {
        Write-Log "TPM version 2.0 is present.OK"
    } else {
        Write-Log "TPM version is below 2.0 — required for Windows 11."
        
    }
} else {
    Write-Log "No TPM detected on this system."
    
}

# Check Secure Boot
$firmwareInfo = Confirm-SecureBootUEFI

if ($firmwareInfo -eq "True") {
    Write-Log "Secure Boot is Enable.OK"
} else {
    Write-Log "Secure Boot is disabled — this is a Windows 11 requirement."
    }

# Check processor architecture
$cpuInfo = Get-WmiObject -Class Win32_Processor
if ($cpuInfo) {
    if ($cpuInfo.Architecture -eq 9) {
        Write-Log "Processor is 64-bit.OK."
    } else {
        Write-Log "Processor is not 64-bit — Windows 11 needs a 64-bit CPU."
     }
}

# Check RAM
$systemSpecs = Get-WmiObject -Class Win32_ComputerSystem
if ($systemSpecs.TotalPhysicalMemory -ge 4GB) {
    Write-Log "System has 4GB or more of RAM.OK"
} else {
    Write-Log "RAM is below 4GB — not sufficient for Windows 11."
 }

# Check storage space
$localDrives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
$availableSpaceGB = [math]::round($localDrives.FreeSpace / 1GB, 2)
if ($availableSpaceGB -ge $DiskSpace) {
    Write-Log "Available disk space is at least $DiskSpace GB.OK"
} else {
    Write-Log "Not enough disk space — Windows 11 needs a minimum of $DiskSpace GB."
}


# Check if system is not on Windows 11 24H2 and meets hardware requirements
if ($OSBuild -lt 26100 -and `
    $tpmVersion -ge "2.0" -and `
    $firmwareInfo -eq "true" -and `
    $cpuInfo.Architecture -eq 9 -and `
    $systemSpecs.TotalPhysicalMemory -ge 4GB -and `
    $availableSpaceGB -ge $DiskSpace) 
{
##Setting Registery to skip Windows PC Health Check status
         Write-log "Setting Registery to skip "PC Health Check tool" to check Upgrade Eligibility Status"
         # Define the registry path
                $regPath = "HKCU:\Software\Microsoft\PCHC"

                    # Create the key if it doesn't exist
                        if (-not (Test-Path $regPath)) {
                         New-Item -Path $regPath -Force | Out-Null
                            }

                            # Set the DWORD value
                    Set-ItemProperty -Path $regPath -Name "UpgradeEligibility" -Value 1 -Type DWord

                    # Confirm the change
                    $Reg = Get-ItemProperty -Path $regPath | Select-Object UpgradeEligibility
                    Write-log "Preparing the device for a Windows 11 upgrade by creating a registry entry to skip the 'PC Health Check Tool' eligibility checks. This is done by creating the registry path HKCU:\Software\Microsoft\PCHC and setting the UpgradeEligibility value (DWORD) to 1."

    Write-Log 'System is not on Windows 11 24H2 and meets hardware requirements. Initiating Proactive Remediation...'
    Write-Host 'System is not on Windows 11 24H2 and meets hardware requirements. Initiating Proactive Remediation...'
    Exit -1
}
elseif ($OSBuild-lt 26100) {
    Write-Log 'System is not on Windows 11 24H2 but does not meet hardware requirements. Skipping upgrade.'
    Write-Host 'System is not on Windows 11 24H2 but does not meet hardware requirements. Skipping upgrade.'
    Exit 0
}
else {
    Write-Log 'System is already on Windows 11 24H2. No remediation needed.'
    Write-Host 'System is already on Windows 11 24H2. No remediation needed.'
    Exit 0
}
