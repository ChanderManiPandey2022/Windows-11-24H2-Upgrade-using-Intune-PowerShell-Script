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

$error.clear() ## this is the clear error history 
clear
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -force
$ErrorActionPreference = 'SilentlyContinue'

# Initialize Logging
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Upgrade_To_Win11_24H2.log"         
Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath  -Append
}
Write-Log "====================== Upgrading Windows 10 to Windows 11 24H2 Using Intune Proactive Remediation Script $(Get-Date -Format 'yyyy/MM/dd') ==================="

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

$OSInfo = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion'
$DevicesInfos ="$($OSInfo.CurrentMajorVersionNumber).$($OSInfo.CurrentMinorVersionNumber).$($OSInfo.CurrentBuild).$($OSInfo.UBR)"
Write-Log "OS Build version $DevicesInfos"

# Get last reboot time
$LastReboot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Log "Machine Last Reboot Time: $LastReboot"

# Get total and free space on C: drive in GB
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$TotalSpaceGB = [math]::round($Disk.Size / 1GB, 2)
$FreeSpaceGB = [math]::round($Disk.FreeSpace / 1GB, 2)

Write-Log "Machine Total C: Drive Space: $TotalSpaceGB GB"
Write-Log "Machine Free  C: Drive Space: $FreeSpaceGB GB"



# Checking Windows Update
$ServiceName = 'wuauserv'
$ServiceType = (Get-Service -Name $ServiceName).StartType
Write-Log "Windows Update Service startup type is '$ServiceType'"
if ([string]$ServiceType -ne 'Manual') {
    Write-Log "Startup type for Windows Update is not Manual. Consider setting it to Manual." "WARNING"
    # Set-Service -Name $ServiceName -StartupType Manual
}

# Checking Microsoft Account Sign-in Assistant Service
$ServiceName = 'wlidsvc'
$ServiceType = (Get-Service -Name $ServiceName).StartType
Write-Log "Microsoft Account Sign-in Assistant Service startup type is '$ServiceType'"
if ([string]$ServiceType -ne 'Manual') {
    Write-Log "Startup type for Microsoft Account Sign-in Assistant is not Manual. Consider setting it to Manual." "WARNING"
    # Set-Service -Name $ServiceName -StartupType Manual
}

# Checking Update Orchestrator Service
$ServiceName = 'UsoSvc'
$ServiceType = (Get-Service -Name $ServiceName).StartType
if ($ServiceType) {
    Write-Log "Update Orchestrator Service startup type is '$ServiceType'"
    if ([string]$ServiceType -ne 'Automatic') {
        Write-Log "Startup type for Update Orchestrator Service is not Automatic. Consider setting it to Automatic." "WARNING"
        # Set-Service -Name $ServiceName -StartupType Automatic
    }
    }

Function Get-LatestWindowsUpdateInfo {
    # Get the current build number
    $currentBuild = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
    $osBuildMajor = $currentBuild.Substring(0, 1)

    # Decide which update history URL to use based on the device OS Win10 or Win11
    $updateUrl = if ($osBuildMajor -eq "2") {
        "https://aka.ms/Windows11UpdateHistory"
    } else {
        "https://support.microsoft.com/en-us/help/4043454"
    }

    # Get the page content
    $response = if ($PSVersionTable.PSVersion.Major -ge 6) {
        Invoke-WebRequest -Uri $updateUrl -ErrorAction Stop
    } else {
        Invoke-WebRequest -Uri $updateUrl -UseBasicParsing -ErrorAction Stop
    }

    # Filter all KB links
    $updateLinks = $response.Links | Where-Object {
        $_.outerHTML -match "supLeftNavLink" -and
        $_.outerHTML -match "KB" -and
        $_.outerHTML -notmatch "Preview" -and
        $_.outerHTML -notmatch "Out-of-band"
    }

    # Get the latest relevant update
    $latest = $updateLinks | Where-Object {
        $_.outerHTML -match $currentBuild
    } | Select-Object -First 1

    if ($latest) {
        $title = $latest.outerHTML.Split('>')[1].Replace('</a','').Replace('&#x2014;', ' - ')
        $kbId  = "KB" + $latest.href.Split('/')[-1]

        [PSCustomObject]@{
            LatestUpdate_Title = $title
            LatestUpdate_KB    = $kbId
        }
    } else {
        Write-log "No update found for current build."
        
    }
}
    
#If you want to restart service remove # from these commands
#Restart-Service -Name wlidsvc -Force
#Restart-Service -Name uhssvc -Force
#Restart-Service -Name wuauserv -Force

# Run and show the result
$latestUpdateInfo = Get-LatestWindowsUpdateInfo
$LastHotFix = $latestUpdateInfo.LatestUpdate_KB
$LastPatchDate = $hotfix.InstalledOn
$KB = $LastHotFix-replace "^KB", ""
$InfoURL = "https://support.microsoft.com/en-us/help/$KB"
Write-Log "Latest Patch Tuesday Security Update KB Number:- $($latestUpdateInfo.LatestUpdate_KB)"
Write-Log "Latest Security Update KB Info URL :- $InfoURL"
Write-Log "Latest Security Update KB Title and Date:- $($latestUpdateInfo.LatestUpdate_Title)"
rebootRequiredKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    if (Test-Path $rebootRequiredKey) {
    $rebootGuid = Get-ItemProperty -Path $rebootRequiredKey 
    $guidOnly = ($rebootGuid | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }) | Where-Object { $_ -match '^[a-f0-9\-]{36}$' }
    if ($rebootGuid)
    
     { Write-Log "Windows Update Reboot pending against.GUID: $guidOnly"
       Write-Log "Manually Reboot the System"
     } 
     else { Write-Log "No Windows Update Patching Reboot Required."}
     }

#https://download.microsoft.com/download/6/8/3/683178b7-baac-4b0d-95be-065a945aadee/Windows11InstallationAssistant.exe

$OSVersion = (Get-WMIObject win32_operatingsystem).buildnumber

if ($OSVersion -lt 26100) {
 Write-Log "System is not on Win11 26100 version.Action Required."
   
    Write-Log "Checking Windows PC Health Check installation status"
    $DownloadDir = "C:\windows\temp\Upgrade_Win11_24H2"
    New-Item -ItemType Directory -Path $DownloadDir
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

        
      #Download the latest windows 11 upgrade assistant 
    Write-Log "Downloading the latest Windows 11 upgrade assistant(Win11_24H2)."
     
    $Url = "https://download.microsoft.com/download/6/8/3/683178b7-baac-4b0d-95be-065a945aadee/Windows11InstallationAssistant.exe"
    
    $UpdaterBinary = "$($DownloadDir)\Windows11InstallationAssistant.exe"
    
    [System.Net.WebClient]$webClient = New-Object System.Net.WebClient
      
    
    if (Test-Path $UpdaterBinary) {
    
        Remove-Item -Path $UpdaterBinary -Force
    }
    
    Write-Log "Windows 11 Installation Assistant.exe downloaded and saved in $UpdaterBinary"
    
    $webClient.DownloadFile($Url, $UpdaterBinary)

    # execute the update in quiet mode. 
    #$UpdaterArguments = '/quietinstall /skipeula /auto upgrade'
    #$UpdaterArguments = '/skipeula /auto upgrade'
    $UpdaterArguments = '/quietinstall /skipeula /auto upgrade'
      

    # $UpdaterArguments = "$updaterbinary /skipeula /auto upgrade"
    Write-Log "Executing Windows 11 Installation Assistant.exe with silent switch and supressing reboot"

    Start-Process -FilePath C:\windows\temp\Upgrade_Win11_24H2\Windows11InstallationAssistant.exe -ArgumentList $UpdaterArguments
    # -Wait
    Start-Sleep -Seconds 30
    $process = Get-Process -Name "Windows10UpgraderApp" -ErrorAction SilentlyContinue


       if ($process) {
        Write-Log "Win11 24H2 Upgrade process is running..."

        # Wait while the process is running
        while (Get-Process -Name "Windows10UpgraderApp" -ErrorAction SilentlyContinue) {
        Write-Log "Win11 24H2 Upgrade process is still running..."
        Start-Sleep -Seconds 30
        }
        
        Write-Log "Win11 24H2 Upgrade completed"

        #Removing Working folders
        Write-Log "Removing $DownloadDir folder" 
        Remove-Item -Path $DownloadDir -Recurse -Force 
        Write-Log "$DownloadDir folder Removed" 
        Write-Host "Upgrade completed. User action is needed to restart the device"   
        Write-Log "Upgrade completed. User action is needed to restart the device"   
        Exit 0

    

        } 
       }
Else 
       {
        Write-Log 'System is already on windows 11 24H2.Skipping upgrade'
        Write-Host 'System is already on windows 11 24H2.Skipping upgrade'
        Exit 0
         }