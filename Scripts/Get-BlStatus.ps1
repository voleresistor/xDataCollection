#region Get-BLStatus
Function Get-BLStatus
{
    <#
    .Synopsis
    Monitor encryption status on remote computers.
    
    .Description
    Using a remote session, get status of system drive encryption on remote computers.
    
    .Parameter ComputerName
    The remote computer to target for monitoring.
    
    .Example
    Get-BLStatus -ComputerName pc001.contoso.com
    
    Get encryption progress updates until encryption is completed.
    #>
    param
    (
        [string]$ComputerName = $env:localhost
    )
    
    try
    {
        # Generate a session to run the remote command in
        $BLMonSession = New-PSSession -ComputerName $ComputerName
        
        do
        {
            $Volume = (Invoke-Command -Session $BLMonSession -ScriptBlock {Get-BitLockerVolume -MountPoint $env:SystemDrive})
            Write-Progress -Activity "Encrypting volume $($Volume.MountPoint) on $ComputerName" -Status "Encryption Progress - $($Volume.EncryptionPercentage)%" -PercentComplete $Volume.EncryptionPercentage
            Start-Sleep -Seconds 1
        }
        until ($Volume.VolumeStatus -eq 'FullyEncrypted')
    }
    
    # We want to kill the previously generated session when we're done
    # no matter what happened in between
    finally
    {
        Remove-PSSession -Id $($a.Id)
    }
}
#endregion
