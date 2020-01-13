#region Get-DiskSize
function Get-DiskSize
{
    <#
        .Synopsis
        Display free and total space on remote and local logical disks.
        
        .Description
        Display free and total space on all remote and local logical disks using WMI.
        
        .Parameter ComputerName
        Name of target computer. Defaults to localhost.
        
        .Example
        Get-DiskSize
        
        Get free and total space in GB on local computer.
    #>
    param
    (
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string[]]$ComputerName = $env:computername,

        [Parameter(Mandatory=$false)]
        [string]$DriveLetter
    )

    #region ConvertLength
    function ConvertLength
    {
        param
        (
            [System.Int64]$Length
        )

        if ($Length -lt 1048576)
        {
            $size = "{0:N2}" -f $($Length / 1kb)
            $unit = 'KB'
        }
        elseif ($Length -lt 1073741824)
        {
            $size = "{0:N2}" -f $($Length / 1mb)
            $unit = 'MB'
        }
        elseif ($Length -lt 1099511627776)
        {
            $size = "{0:N2}" -f $($Length / 1gb)
            $unit = 'GB'
        }
        else
        {
            $size = "{0:N2}" -f $($Length / 1tb)
            $unit = 'TB'
        }

        return "$size $unit"
    }
    #endregion
    
    # Create an array to hold our objects
    $AllMembers = @()
    $count = $ComputerName.Count
    
    foreach ($Computer in $ComputerName)
    {
        $idx = [array]::IndexOf($ComputerName, $Computer) + 1
        Write-Progress -Activity 'Getting disk info...' -Status $Computer -PercentComplete (($idx / $count) * 100)

        if ($DriveLetter)
        {
            $Disks = Get-CimInstance -ClassName Win32_Volume -ComputerName $Computer -ErrorAction SilentlyContinue |
                Where-Object {$_.DriveLetter -eq $DriveLetter + ":"}
        }
        else
        {
            $Disks = Get-CimInstance -ClassName Win32_Volume -ComputerName $Computer -ErrorAction SilentlyContinue |
                Where-Object {$_.DriveType -eq 3}
        }

        foreach ($disk in $Disks)
        {
            <#if (($disk.Label -eq 'System Reserved') -or ($disk.Label -eq 'RECOVERY') -or ($disk.Label -eq 'SYSTEM'))
            {
                continue
            }#>
            
            $FreeSpace = ConvertLength -Length $disk.FreeSpace
            $TotalSize = ConvertLength -Length $disk.Capacity
            $UsedSpace = ConvertLength -Length ($($disk.Capacity) - $($disk.FreeSpace))
            $DiskLabel = $($disk.Label)
            $DiskLetter = $($disk.DriveLetter)
            
            # Create and populate an object for each disk
            $DiskObj = New-Object -TypeName PSObject
            $DiskObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer
            $DiskObj | Add-Member -MemberType NoteProperty -Name DiskLabel -Value $DiskLabel
            $DiskObj | Add-Member -MemberType NoteProperty -Name FreeSpace -Value $FreeSpace
            $DiskObj | Add-Member -MemberType NoteProperty -Name UsedSpace -Value $UsedSpace
            $DiskObj | Add-Member -MemberType NoteProperty -Name TotalSize -Value $TotalSize
            $DiskObj | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $DiskLetter
            
            # Add object to collection array
            $AllMembers += $DiskObj
            
            # Cleanup
            $allThoseVars = @(
                'FreeSpace',
                'TotalSize',
                'UsedSpace',
                'DiskLabel',
                'DiskLetter',
                'DiskObj'
            )

            foreach ($v in $allThoseVars)
            {
                if (Get-Variable -Name $v -ErrorAction SilentlyContinue)
                {
                    Clear-Variable -Name $v
                }
            }
        }
        
        # Cleanup
        if (Get-Variable -Name 'Disks' -ErrorAction SilentlyContinue)
        {
            Clear-Variable Disks
        }
    }
    
    return $AllMembers
}
<#
    CHANGELOG
    01/06/2020
        Replace Get-WmiObject with Get-CimInstance
#>
<#
    PS C:\> Get-DiskSize | ft

    ComputerName DiskLabel  FreeSpaceGB UsedSpaceGB TotalSizeGB DriveLetter
    ------------ ---------  ----------- ----------- ----------- -----------
    localhost    System     0.15        0.34        0.49
    localhost    New Volume 417.65      48.11       465.76      D:
    localhost    Recovery   0.30        0.19        0.49        E:
    localhost    OSDisk     32.41       199.50      231.91      C:
    
    
    PS C:\>
                     
#>
#endregion
