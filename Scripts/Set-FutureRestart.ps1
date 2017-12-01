#region Set-FutureRestart
function Set-FutureRestart
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
        [datetime]$RestartTime = '21:00',
        [string]$Computername = $env:localhost,
        [string]$Name = 'Scheduled Restart',
        [string]$Description = 'Scheduled after-hours restart.'
    )

    Invoke-Command -ComputerName $Computername -Args $RestartTime,$Name,$Description -ScriptBlock{
        $ExePath = "%windir%\System32\WindowsPowerShell\v1.0\PowerShell.exe"
        $ActionArg = '-NoProfile -WindowStyle Hidden -Command "Restart-Computer -Force"'
        $TaskName = $args[1]
        $TaskDesc = $args[2]
        $RunTime = $args[0]
        
        #Make sure we delete any previously scheduled restarts
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction Ignore)
        {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        
        #Register this MOF to enable PowerShell task scheduling
        mofcomp C:\Windows\System32\wbem\SchedProv.mof
        $STAction = New-ScheduledTaskAction -Execute $ExePath -Argument $ActionArg
        $STTrigger = New-ScheduledTaskTrigger -Once -At $RunTime
        Register-ScheduledTask -TaskName $TaskName -Description $TaskDesc -User 'SYSTEM' -Action $STAction -Trigger $STTrigger
    }
}
#endregion
