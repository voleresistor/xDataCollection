#region Get-LocalTime
Function Get-LocalTime()
{
    <#
    .Synopsis
    Convert UTC to local time.
    
    .Description
    Using local timezone data, convert UTC/GMT time to local time.
    
    .Parameter UTCTime
    A UTC datetime object or string which PowerShell can interpret as a datetime.
    
    .Example
    Get-LocalTime -UTCTime "21:00 07/30/16"
    
    Get UTC time converted to local time.
    #>

    param
    (
        [Parameter(Mandatory=$true)]
        [datetime]$SourceTime
    )

    $strCurrentTimeZone = (Get-CimInstance -ClassName win32_timezone).StandardName
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($SourceTime, $TZ)
    Return $LocalTime
}
<#
    CHANGELOG
    01/06/2020
        Replace Get-WmiObject with Get-CimInstance
#>
<#
    PS C:\> Get-LocalTime -UTCTime "21:00 07/30/16"
    
    Saturday, July 30, 2016 4:00:00 PM
    PS C:\>
#>
#endregion
