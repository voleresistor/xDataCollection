#region Get-MemoryStats
Function Get-MemoryStats {
    <#
    .Synopsis
    Displays information about memory usage on local and remote computers
    
    .Description
    Collect and display information such as free, used, and total memory. Additionally
    displays free and used memory as a percent of total.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Example
    Get-MemoryStats
    
    Get data from the local computer
    
    .Example
    Get-MemoryStats -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    #>

    param (
        # Take an array as input so we can pipe a list of computers in
        [parameter (
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$ComputerName = '.'
    )

    # Get relevant memory info from WMI on the target computer
    try {
        $MemorySpecs = Get-CimInstance -ClassName Win32_Operatingsystem -ComputerName $ComputerName -ErrorAction SilentlyContinue | Select-Object FreePhysicalMemory,TotalVisibleMemorySize
    }
    catch {
        Write-Error $_.Exception.Message
        continue
    }
    
    # Create some variables using the data from the WMI query
    $FreeMemory = $MemorySpecs.FreePhysicalMemory
    $TotalMemory = $MemorySpecs.TotalVisibleMemorySize
    $UsedMemory = $TotalMemory - $FreeMemory
    
    if ($null -eq $FreeMemory) {
        $FreeMemoryPercent = 0
        $UsedMemoryPercent = 0
    }
    else {
        $FreeMemoryPercent   = "{0:N2}" -f (($FreeMemory / $TotalMemory) * 100)
        $UsedMemoryPercent   = "{0:N2}" -f (100 - $FreeMemoryPercent)
    }
    
    $FreeMemory = Convert-ByteLength -Length $($FreeMemory * 1024) -DesiredSize GB
    $TotalMemory = Convert-ByteLength -Length $($TotalMemory * 1024) -DesiredSize GB
    $UsedMemory = Convert-ByteLength -Length $($UsedMemory * 1024) -DesiredSize GB
    
    # Create and populate an object for the data
    $FreeAndTotal = New-Object -TypeName PSObject
    $FreeAndTotal | Add-Member -MemberType NoteProperty -Name TotalMemoryGB -Value $TotalMemory.Size
    $FreeAndTotal | Add-Member -MemberType NoteProperty -Name FreeMemoryGB -Value $FreeMemory.Size
    $FreeAndTotal | Add-Member -MemberType NoteProperty -Name UsedMemoryGB -Value $UsedMemory.Size
    $FreeAndTotal | Add-Member -MemberType NoteProperty -Name FreeMemoryPercent -Value $FreeMemoryPercent
    $FreeAndTotal | Add-Member -MemberType NoteProperty -Name UsedMemoryPercent -Value $UsedMemoryPercent
    $FreeAndTotal | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName

    return $FreeAndTotal
}
<#
    CHANGELOG
    01/06/2020
        Replace Get-WmiObject with Get-CimInstance
    02/24/2020
        Replace $env:computername as default $ComputerName with '.' for Get-CimInstance compatibility
    02/25/2020
        Remove loop to take multiple inputs. Convert function to use Convert-ByteLength. Move ComputerName to end
        of custom object.
#>
<#    
    Example Output:
    
    PS C:\> (Get-ADComputer -Filter {Enabled -eq 'True'}).Name | %{ Get-MemoryStats -ComputerName $_ } | ft
    TotalMemoryGB FreeMemoryGB UsedMemoryGB FreeMemoryPercent UsedMemoryPercent ComputerName
    ------------- ------------ ------------ ----------------- ----------------- ------------
                4         0.69          3.3             17.36             82.64 Server1
                8         5.24         2.76             65.52             34.48 Server2
                4         1.59         2.41             39.78             60.22 Server3
               12         2.52         9.48             20.96             79.04 Server4
                8         6.89         1.11             86.13             13.87 Server5
                8         3.97         4.03             49.66             50.34 Server6
                4          2.1          1.9             52.46             47.54 Server7
               10            9            1             90.03              9.97 Server8
                8         7.02         0.98             87.75             12.25 Server9
               16        14.07         1.93             87.94             12.06 Server0
    snip...

    PS C:\>
#>
#endregion
