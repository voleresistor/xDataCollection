<#
    Custom Functions to make common data data more easily readable or collectable
    than might otherwise be possible using existing tools and methods.
    
    Created 04/22/2016
    Updated 12/01/2017
            01/06/2020
                Add Get-UpgradeHistory
                Replace usage of Get-WmiObject with Get-CimInstance for compatibility with PowerShell 7

    Included functions:
        'Convert-ByteLength',
        'Get-BLStatus',
        'Get-DFSRStats',
        'Get-DiskSize',
        'Get-FileLength',
        'Get-FolderSize',
        'Get-FoldersWithoutInheritance',
        'Get-InstalledSoftware',
        'Get-InstalledSoftware',
        'Get-LocalTime',
        'Get-MemoryStats',
        'Get-OldFiles',
        'Get-OSVersion',
        'Get-RandomWords',
        'Get-RegKeyProperties',
        'Get-ReplStatus',
        'Get-UpgradeHistory',
        'Get-Uptime',
        'New-Password',
        'New-RandomPhrase',
        'New-RestartTask',
        'New-WaitSpan',
        'Start-CountDown'
#>

foreach ($Script in Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter *.ps1)
{
    . $Script.FullName
}
