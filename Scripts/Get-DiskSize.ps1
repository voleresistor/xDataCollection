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
        [string[]]$ComputerName = $env:computername
    )
    
    begin
    {
        # Create an array to hold our objects
        $AllMembers = @()
    }
    
    process
    {
        foreach ($Computer in $ComputerName)
        {
            $Disks = Get-WmiObject -Class Win32_Volume -ComputerName $ComputerName | Where-Object {$_.DriveType -eq 3}
            
            foreach ($disk in $Disks)
            {
                if ($disk.Label -eq 'System Reserved')
                {
                    continue
                }
                
                $FreeSpace = "{0:N2}" -f ($disk.FreeSpace / 1gb)
                $TotalSize = "{0:N2}" -f ($disk.Capacity / 1gb)
                $UsedSpace = "{0:N2}" -f ($TotalSize - $FreeSpace)
                $DiskLabel = $($disk.Label)
                $DiskLetter = $($disk.DriveLetter)
                
                # Create and populate an object for each disk
                $DiskObj = New-Object -TypeName PSObject
                $DiskObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer
                $DiskObj | Add-Member -MemberType NoteProperty -Name DiskLabel -Value $DiskLabel
                $DiskObj | Add-Member -MemberType NoteProperty -Name FreeSpaceGB -Value $FreeSpace
                $DiskObj | Add-Member -MemberType NoteProperty -Name UsedSpaceGB -Value $UsedSpace
                $DiskObj | Add-Member -MemberType NoteProperty -Name TotalSizeGB -Value $TotalSize
                $DiskObj | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $DiskLetter
                
                # Add object to collection array
                $AllMembers += $DiskObj
                
                # Cleanup
                Clear-Variable FreeSpace,TotalSize,UsedSpace,DiskLabel,DiskLetter,DiskObj
            }
            
            # Cleanup
            Clear-Variable Disks
        }
    }
    
    end
    {
        return $AllMembers
    }
}
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
