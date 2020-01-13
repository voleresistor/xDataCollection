#region Get-Uptime
function Get-Uptime
{
    <#
    .Synopsis
    Displays information about uptime on local and remote computers
    
    .Description
    Collect and display information about computer uptime calculated from data on
    the remote computer.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Example
    Get-Uptime
    
    Get data from the local computer
    
    .Example
    Get-Uptime -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    #>
    param
    (
        # Take an array as input so we can pipe a list of computers in
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [array]$ComputerName = @('localhost')
    )
    
    begin
    {
        # Create an array to hold our objects
        $AllMembers = @()
    }
    
    process
    {
        foreach ($target in $ComputerName)
        {
            # Make sure we can even talk to the target. If not, cancel this loop and move on
            if (!(Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue))
            {
                continue
            }
            
            # Get relevant memory info from WMI on the target computer
            $OSSpecs = Get-CimInstance -ClassName Win32_Operatingsystem -ComputerName $target
            
            # Convert LastBootUpTime into a useful DateTime object and Use it to calculate total uptime
            $LastBootTime   = $OSSpecs.LastBootUpTime
            $CurrentTime    = $OSSpecs.LocalDateTime
            $Uptime         = $CurrentTime - $LastBootTime
            
            # Convert these values to use leading zeroes for consistency
            [string]$Days       = $Uptime.Days
            [string]$Hours      = $Uptime.Hours
            [string]$Minutes    = $Uptime.Minutes
            [string]$Seconds    = $Uptime.Seconds
            $Hours              = $Hours.PadLeft(2,"0")
            $Minutes            = $Minutes.PadLeft(2,"0")
            $Seconds            = $Seconds.PadLeft(2,"0")
            $Uptime             = "$Days`.$Hours`:$Minutes`:$Seconds"
            
            # Convert LastBootUpTime to local time in case of time zone discrepancy
            # TODO: Test this more. It appears to have converted a local time into UTC
            <#
            if (($LastBootTime.AddHours(1) -))
            $LastBootTime       = $LastBootTime.ToLocalTime()
            #>
            
            # Create a custom object to store our data before returning it
            $TimeData = New-Object -TypeName PSObject
            $TimeData | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Target
            $TimeData | Add-Member -MemberType NoteProperty -Name UpTime -Value $Uptime
            $TimeData | Add-Member -MemberType NoteProperty -Name LastBootTime -Value $LastBootTime
            
            # Add object to collection array
            $AllMembers += $TimeData
        }
    }
    
    end
    {    
        # Return collected data
        return $AllMembers
    }
}
<#
    CHANGELOG
    01/06/2020
        Replace Get-WmiObject with Get-CimInstance
#>
<#
    Example Output:
    
    PS C:\> Get-Uptime -ComputerName $(Get-ADComputer -Filter {enabled -eq 'True'}).Name | ft
    ComputerName UpTime      LastBootTime
    ------------ ------      ------------
    RIGEL        22.01:26:00 4/2/2016 6:45:04 PM
    SOL          0.16:47:24  4/24/2016 3:23:41 AM
    APODIS       4.04:03:51  4/20/2016 4:07:14 PM
    VYCANIS      22.01:33:23 4/2/2016 6:37:42 PM
    SADATONI     22.01:23:41 4/2/2016 6:47:24 PM
    DENEB        2.02:38:50  4/22/2016 5:32:15 PM
    RANA         22.01:21:33 4/2/2016 6:49:33 PM
    POLONIUM     2.01:33:15  4/22/2016 6:37:53 PM
#>
#endregion
