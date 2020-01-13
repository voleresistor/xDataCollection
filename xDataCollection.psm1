<#
    Custom Functions to make common data data more easily readable or collectable
    than might otherwise be possible using existing tools and methods.
    
    Created 04/22/2016
    Updated 12/01/2017
            01/06/2020
                Add Get-UpgradeHistory
                Replace usage of Get-WmiObject with Get-CimInstance for compatibility with PowerShell 7

    Included functions:
        'Get-MemoryStats',
        'Get-OSVersion',
        'Get-Uptime',
        'Get-InstalledSoftware',
        'Get-FolderSize',
        'Get-InstalledSoftware',
        'New-Password',
        'Get-OldFiles',
        'Get-DiskSize',
        'Get-DFSRStats',
        'Get-LocalTime',
        'New-RestartTask',
        'Get-BLStatus',
        'Get-RandomWords',
        'New-RandomPhrase',
        'Start-CountDown',
        'Get-ReplStatus',
        'New-WaitSpan',
        'Get-FileLength',
        'Get-FoldersWithoutInheritance',
        'Get-RegKeyProperties',
        'Get-UpgradeHistory'
#>

foreach ($Script in Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter *.ps1)
{
    . $Script.FullName
}
