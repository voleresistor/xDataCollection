#region Start-CountDown
Function Start-CountDown
{
    <#
    .Synopsis
    ***Can this pop up a notification on screen when the countdown is complete? - AO 12/01/17***
    Begins a visual countdown for use as a timer or alarm or simple task scheduler.
    
    .Description
    Takes wait time in seconds, minutes, hours or a completion time. Displays a countdown on screen with progress bar. Exits silently at end of countdown.
    
    .Parameter ActivityName
    Name of the activity being counted down.
    
    .Parameter WaitSeconds
    Number of seconds to wait. This is exclusive with other $Wait<time> parameters.
    
    .Parameter WaitMinutes
    Number of minutes to wait. This is exclusive with other $Wait<time> parameters.
    
    .Parameter WaitHours
    Number of hours to wait. This is exclusive with other $Wait<time> parameters.
    
    .Parameter WaitUntil
    Time in DateTime format to end countdown. This is exclusive with other $Wait<time> parameters.

    .PARAMETER ShowNotification
    Pop up a small notice window to inform the user that the countdown has completed.
    
    .Example
    Start-CountDown -ActivityName 'Wait for task completion' -WaitSeconds 15
    
    Begin a 15 second countdown.
    
    .Example
    Start-CountDown -ActivityName 'Wait for task completion' -WaitHours 2
    
    Begin a 2 hour countdown.
    
    .Example
    Start-CountDown -ActivityName 'Wait for task completion' -WaitUntil "11/19/2016"
    
    Begin a countdown until the specified date.
    #>
    
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$ActivityName,
        
        [Parameter(Mandatory=$false,ParameterSetName='Seconds')]
        [int]$WaitSeconds,
        
        [Parameter(Mandatory=$false,ParameterSetName='Minutes')]
        [int]$WaitMinutes,
        
        [Parameter(Mandatory=$false,ParameterSetName='Hours')]
        [int]$WaitHours,
        
        [Parameter(Mandatory=$false,ParameterSetName='WaitUntil')]
        [datetime]$WaitUntil,

        [Parameter(Mandatory=$false)]
        [switch]$ShowNotification
    )
    
    try
    {
        if ($WaitMinutes)
        {
            $WaitSeconds = $WaitMinutes * 60
        }
        elseif ($WaitHours)
        {
            $WaitSeconds = $WaitHours * 3600
        }
        elseif ($WaitUntil)
        {
            $WaitSeconds = (New-TimeSpan -Start (Get-Date) -End $WaitUntil).TotalSeconds
        }
        
        for ($t = 0; $t -lt $WaitSeconds; $t++)
        {
            $CurrentSpan = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddSeconds($WaitSeconds - $t)
            $PercentComplete = ($t / $WaitSeconds) * 100
            
            $Hours = "{0:D2}" -f $($CurrentSpan.Hours)
            $Minutes = "{0:D2}" -f $($CurrentSpan.Minutes)
            $Seconds = "{0:D2}" -f $($CurrentSpan.Seconds)
            
            if ($CurrentSpan.Days -ne 0)
            {
                $Days = "{0:D2}" -f $($CurrentSpan.Days)
                $TimeLeft = "$Days`:$Hours`:$Minutes`:$Seconds"
            }
            else
            {
                $TimeLeft = "$Hours`:$Minutes`:$Seconds"
            }
            
            Write-Progress -Activity $ActivityName -Status "$TimeLeft remaining..." -PercentComplete $PercentComplete
            start-sleep -Seconds 1
            
            Clear-Variable CurrentSpan,PercentComplete,Hours,Minutes,Seconds,TimeLeft
        }
    }
    catch
    {
        
    }
    finally
    {
        if ($ShowNotification)
        {
            #Create Default Document Form
            Add-Type -AssemblyName System.Windows.Forms
            $msgForm = New-Object Windows.Forms.Form
            $msgForm.Size = New-Object Drawing.Size @(400,200)
            $msgForm.StartPosition = "CenterScreen"
            $msgForm.Text = $ActivityName

            #Write Message on msgForm Box
            $msgLabel = New-Object System.Windows.Forms.Label
            $msgLabel.Location = New-Object System.Drawing.Size(0,0)
            $msgLabel.Size = New-Object System.Drawing.Size(400,200)
            $msgLabel.Text = "Completed at $(Get-Date)"
            $msgForm.Controls.Add($msgLabel)

            #Display msgForm
            $msgForm.ShowDialog()
        }
    }
}
#endregion