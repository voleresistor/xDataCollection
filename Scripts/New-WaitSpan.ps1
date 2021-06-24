function New-WaitSpan
{
    <#
    .SYNOPSIS
    Wait until specified time.
    
    .DESCRIPTION
    Wait until time given with a countdown and progress bar visible.
    
    .PARAMETER WaitEnd
    A datetime formatted string denoting the time to stop waiting.
    
    .PARAMETER Activity
    A simple description of what's being waited for.
    
    .EXAMPLE
    New-WaitSpan -WaitEnd "13:50"
    Wait until 1:50pm with default Activity of "Waiting..."
    
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true, Position=1)]
        [datetime]$WaitEnd,

        [parameter(Mandatory=$false, Position=2)]
        [string]$Activity = "Waiting..."
    )

    [timespan]$Initial = New-TimeSpan -Start (Get-Date) -End $WaitEnd

    while ($WaitEnd -gt (Get-Date))
    {
        [timespan]$Current = New-TimeSpan -Start (Get-Date) -End $WaitEnd

        # Build our data for this cycle
        # Split uses a simple regex to dump the milliseconds
        [String]$Status = ($Current.ToString() -split('\.[\d]{7}'))[0]
        [int]$PercentComp = $((($($Initial.TotalSeconds) - $($Current.TotalSeconds)) / $($Initial.TotalSeconds)) * 100)

        # Display and wait
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComp
        Start-Sleep -Seconds 1
    }
}

<#
    Changes
    05/24/21:
        Replace complex string builder for timespan with .ToString() TimeSpan method
#>