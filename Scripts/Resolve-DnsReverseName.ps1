function Resolve-DnsReverseName {
    <##>

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            HelpMessage = 'An IP address on which to perform a reverse DNS query.'
        )]
        [ValidatePattern('^(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$')]
        [string]$IPAddress
    )

    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $result = [System.Net.Dns]::GetHostByAddress($IPAddress)
    $ErrorActionPreference = $oldEAP

    if ($result) {
        return $result
    }
}