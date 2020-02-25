#region Get-DiskSize
function Get-DiskSize {
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
    
    param (
        [parameter (
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$ComputerName = '.',

        [Parameter(Mandatory=$false)]
        [string]$DriveLetter
    )

    # An array for the disks
    $ArrDisks = @()

    if ($DriveLetter) {
        $Disks = Get-CimInstance -ClassName Win32_Volume -ComputerName $ComputerName -ErrorAction SilentlyContinue |
            Where-Object {$_.DriveLetter -eq $DriveLetter + ":"}
    }
    else {
        $Disks = Get-CimInstance -ClassName Win32_Volume -ComputerName $ComputerName -ErrorAction SilentlyContinue |
            Where-Object {$_.DriveType -eq 3}
    }

    foreach ($disk in $Disks) {           
        $FreeSpace = Convert-ByteLength -Length $disk.FreeSpace
        $FreeSpace = "$($FreeSpace.Size) $($FreeSpace.Unit)"
        $TotalSize = Convert-ByteLength -Length $disk.Capacity
        $TotalSize = "$($TotalSize.Size) $($TotalSize.Unit)"
        $UsedSpace = Convert-ByteLength -Length ($($disk.Capacity) - $($disk.FreeSpace))
        $UsedSpace = "$($UsedSpace.Size) $($UsedSpace.Unit)"
        $DiskLabel = $($disk.Label)
        $DiskLetter = $($disk.DriveLetter)
        
        # Create and populate an object for each disk
        $DiskObj = New-Object -TypeName PSObject
        $DiskObj | Add-Member -MemberType NoteProperty -Name DiskLabel -Value $DiskLabel
        $DiskObj | Add-Member -MemberType NoteProperty -Name FreeSpace -Value $FreeSpace
        $DiskObj | Add-Member -MemberType NoteProperty -Name UsedSpace -Value $UsedSpace
        $DiskObj | Add-Member -MemberType NoteProperty -Name TotalSize -Value $TotalSize
        $DiskObj | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $DiskLetter
        $DiskObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
        
        # Add object to collection array
        $ArrDisks += $DiskObj
    }
    
    return $ArrDisks
}
<#
    CHANGELOG
    01/06/2020
        Replace Get-WmiObject with Get-CimInstance
    02/25/2020
        Rewrite to remove main computer loop. Function may now only act on a single target at a time. Remove
        ConvertLength and create a separate function. Update to handle object returned from ConvertLength.
        Move ComputerName to end of return object. Replace $env:computername with '.' to make local use compatible
        with Get-CimInstance
#>
<#
    PS C:\> Get-DiskSize | ft

    DiskLabel  FreeSpace UsedSpace TotalSize DriveLetter ComputerName
    ---------  --------- --------- --------- ----------- ------------
    OS         48.39 GB  188.83 GB 237.22 GB C:          .
    WINRETOOLS 362.84 MB 627.16 MB 990 MB                .
    ESP        85.62 MB  60.38 MB  146 MB                .
       
    PS C:\>
                     
#>
#endregion
