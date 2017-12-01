#region Get-LocalTime
Function Get-LocalTime($UTCTime)
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
    $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    Return $LocalTime
}
<#
    PS C:\> Get-LocalTime -UTCTime "21:00 07/30/16"
    
    Saturday, July 30, 2016 4:00:00 PM
    PS C:\>
#>
#endregion
