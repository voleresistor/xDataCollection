#region Set-FutureRestart
function New-RestartTask
{
    <#
    .Synopsis
    ***NEEDS REVIEW (Is there a way to handle cleaning up after a restart?) - AO 12/01/17***
    Schedule a reboot on local or remote computer.
    
    .Description
    Use PowerShell and PowerShell remoting to create a one time scheduled task on the local or remote host.
    
    .Parameter RestartTime
    A string which can be interpreted as a DateTime object. This is the time you'd like the restart to be executed. Defaults to 9:00PM.
    
    .Parameter ComputerName
    The name of the target computer. Defaults to localhost.
    
    .Parameter Name
    Name of the scheduled task as it will appear in Task Scheduler. Defaults to 'Scheduled Restart.'
    
    .Parameter Description
    Description applied to the scheduled task in Task Scheduler. Defaults to 'Scheduled after-hours restart.'
    
    .Example
    Set-FutureRestart
    
    Schedule the local computer to restart at 9:00PM.
    
    .Example
    Set-FutureRestart -ComputerName 'remote.domain.com' -RestartTime 23:50
    
    Schedule the remote host 'remote.domain.com' to restart at 11:50PM.
    #>
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Computername,

        [Parameter(Mandatory=$true, Position=2)]
        [datetime]$RestartTime,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$Name
    )

    [xml]$TemplateXml = 
@"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
    <RegistrationInfo>
    <Date></Date>
    <Author></Author>
    <URI></URI>
    </RegistrationInfo>
    <Triggers>
    <TimeTrigger>
        <StartBoundary></StartBoundary>
        <EndBoundary></EndBoundary>
        <Enabled>true</Enabled>
    </TimeTrigger>
    </Triggers>
    <Principals>
    <Principal id="Author">
        <UserId>S-1-5-18</UserId>
        <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
    </Principals>
    <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
        <StopOnIdleEnd>true</StopOnIdleEnd>
        <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <DeleteExpiredTaskAfter>PT0S</DeleteExpiredTaskAfter>
    <Priority>7</Priority>
    </Settings>
    <Actions Context="Author">
    <Exec>
        <Command>%windir%\system32\cmd.exe</Command>
        <Arguments>/C shutdown -r -t 300 /c "Scheduled restart by {DATA}"</Arguments>
    </Exec>
    </Actions>
</Task>
"@

    $DateFormat = 'yyyy-MM-ddTHH:mm:ss.fffffff'
    # Configure RegistrationInfo
    $TemplateXml.Task.RegistrationInfo.Date = $(Get-Date -Format $DateFormat).ToString()
    $TemplateXml.Task.RegistrationInfo.Author = "$Env:USERDOMAIN\$env:USERNAME"
    $TemplateXml.Task.RegistrationInfo.URI = "\$Name"

    # Configure Triggers
    $TemplateXml.Task.Triggers.TimeTrigger.StartBoundary = $(Get-Date -Date $RestartTime -Format $DateFormat).ToString()
    $TemplateXml.Task.Triggers.TimeTrigger.EndBoundary = $(Get-Date -Date $($RestartTime.AddHours(1)) -Format $DateFormat).ToString()

    # Configure Actions
    $AuthorString = "$Env:USERDOMAIN\$env:USERNAME from $env:COMPUTERNAME"
    $TemplateXml.Task.Actions.Exec.Arguments = $TemplateXml.Task.Actions.Exec.Arguments -replace ('{DATA}', $AuthorString)

    try
    {
        $TemplateXml.save("\\$ComputerName\admin$\temp\restart.xml")
    }
    catch
    {
        Write-Host "Can't save template file to target host!"
        return 2
    }

    try
    {
        $remote = New-PSSession -ComputerName $Computername
        Invoke-Command -Session $remote -ScriptBlock { Start-Process -FilePath "$env:Windir\System32\SchTasks.exe" -ArgumentList "/create /xml `"$env:Windir\Temp\restart.xml`" /tn `"$($args[0])`"" } -ArgumentList $Name
        Write-Host "Scheduled task set!"
        return 0
    }
    finally
    {
        Remove-PSSession -Session $remote
    }
}
#endregion
