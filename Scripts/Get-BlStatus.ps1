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

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false, Position=1)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false, Position=2)]
        [int]$SleepSeconds = 5
    )

    if ($ComputerName) {
        # Generate a session to run the remote command in
        $BLMonSession = New-PSSession -ComputerName $ComputerName
    }
    
    do
    {
        # Get the volume info
        if ($BLMonSession) {
            $Volume = (Invoke-Command -Session $BLMonSession -ScriptBlock { Get-BitLockerVolume `
            -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue })
        }
        else {
            $Volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
        }

        # If no volume info, then quit and complain
        if (!($Volume))
        {
            Write-Error "Can't get volume information. Are you admin/elevated?"
            break
        }

        # If volume is not being encrypted, let user know (verbose) and break
        if ($Volume.VolumeStatus -eq 'FullyDecrypted') {
            Write-Verbose "Volume $($Volume.MountPoint) on $($Volume.ComputerName) is fully decrypted."
            break
        }

        # If volume is encrypted, let user know (verbose) and break
        if ($Volume.VolumeStatus -eq 'FullyEncrypted') {
            Write-Verbose "Volume $($Volume.MountPoint) on $($Volume.ComputerName) is fully encrypted."
            break
        }

        # Set encrypt/decrypt variables based on current status
        if ($Volume.VolumeStatus -eq 'EncryptionInProgress') {
            $Activity = "Encrypting"
            $Status = "Encryption"
        }
        else {
            $Activity = "Decrypting"
            $Status = "Decryption"
        }

        # If there is reportable progress, write to PS console
        Write-Progress -Activity "$Activity volume $($Volume.MountPoint) on $(if ($ComputerName){$ComputerName} `
        else{'localhost'})" -Status "$Status Progress - $($Volume.EncryptionPercentage)%" `
        -PercentComplete $Volume.EncryptionPercentage
        Start-Sleep -Seconds $SleepSeconds
    }
    until ($Volume.VolumeStatus -eq 'FullyEncrypted')
    
    # If a remote session exists, clean it up
    if ($BLMonSession) {
        Remove-PSSession -Id $($BLMonSession.Id) -ErrorAction SilentlyContinue
    }
}
<#
    CHANGELOG
    02/24/2020
        Full rewrite to improve error handling and user friendliness
#>
#endregion