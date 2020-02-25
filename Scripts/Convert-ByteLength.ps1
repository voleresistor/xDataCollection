#region ConvertLength
function Convert-ByteLength {
    <#
    .Synopsis
    Convert file length to easier to read values.
    
    .Description
    Convert byte lengths into human readable values based on size. Returns a small custom object.
    
    .Parameter Length
    The length of the file in bytes.

    .Parameter DesiredSize
    The size the user prefers the return object to be measured in.
    
    .Example
    Convert-ByteLength -Length 111111111
    
    Automatically convert 111111111 bytes to 105.96 MB.

    .Example
    Convert-ByteLength -Length 111111111 -DesiredSize GB

    Convert 111111111 to 
    #>

    param (
        [Parameter(Mandatory=$true, Position=1)]
        [System.Int64]$Length,

        [Parameter(Mandatory=$false, Position=2)]
        [ValidateSet('KB', 'MB', 'GB', 'TB')]
        [string]$DesiredSize
    )

    # Define some size breakpoints
    $TB = 1099511627776
    $GB = 1073741824
    $MB = 1048576

    # Create a custom object to hold size information
    $SizeObj = New-Object -TypeName psobject
    $SizeObj | Add-Member -MemberType NoteProperty -Name 'RawSize' -Value $Length
    $SizeObj | Add-Member -MemberType NoteProperty -Name 'Size' -Value $null
    $SizeObj | Add-Member -MemberType NoteProperty -Name 'Unit' -Value $null

    # Convert to most appropriate (or requested) size and store as a float value
    if ($Length -ge $TB -or $DesiredSize -eq 'TB') {
        $ConvertedSize = [float]$("{0:N2}" -f $($Length / 1tb))
        $SizeObj.Unit = 'TB'
        $SizeObj.Size = $ConvertedSize
        return $SizeObj
    }

    if (($Length -lt $TB -and $Length -ge $GB) -or ($DesiredSize -eq 'GB')) {
        $ConvertedSize = [float]$("{0:N2}" -f $($Length / 1gb))
        $SizeObj.Unit = 'GB'
        $SizeObj.Size = $ConvertedSize
        return $SizeObj
    }

    if (($Length -lt $GB -and $Length -ge $MB) -or ($DesiredSize -eq 'MB')) {
        $ConvertedSize = [float]$("{0:N2}" -f $($Length / 1mb))
        $SizeObj.Unit = 'MB'
        $SizeObj.Size = $ConvertedSize
        return $SizeObj
    }

    if (($Length -lt $MB) -or ($DesiredSize -eq 'KB')) {
        $ConvertedSize = [float]$("{0:N2}" -f $($Length / 1kb))
        $SizeObj.Unit = 'KB'
        $SizeObj.Size = $ConvertedSize
        return $SizeObj
    }
    
    # We shouldn't ever hit this point, but just in case, return the object with null values
    return $SizeObj
}
<#
    CHANGELOG

    Example Output:
    PS C:\> Convert-ByteLength -Length 111111111

      RawSize   Size Unit
      -------   ---- ----
    111111111 105.96 MB

    PS C:\> Convert-ByteLength -Length 111111111 -DesiredSize GB

      RawSize Size Unit
      ------- ---- ----
    111111111  0.1 GB

    PS C:\>
#>
#endregion