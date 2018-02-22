<#
    Custom Functions to make common data data more easily readable or collectable
    than might otherwise be possible using existing tools and methods.
    
    Created 04/22/16
    Updated 12/01/17

    Included functions:
        Get-MemoryStats
        Get-OSVersion
        Get-Uptime
        Get-InstalledSoftware
        Get-FolderSize
        Get-InstalledSoftware
        New-Password
        Get-OldFiles
        Get-DiskSize
        Get-DFSRStats
        Get-LocalTime
        New-RestartTask
        Get-BLStatus
        Get-RandomWords
        New-RandomPhrase
        Start-CountDown
        Get-ReplStatus
        New-WaitSpan
#>

foreach ($Script in Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter *.ps1)
{
    . $Script.FullName
}
