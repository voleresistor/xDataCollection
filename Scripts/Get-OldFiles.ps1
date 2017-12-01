#region Get-OldFiles
function Get-OldFiles
{
<#
    .Synopsis
    Display space used by old files.
    
    .Description
    Gathers used space in folders based on maximum age. Files younger than max age are ignored.
    
    .Parameter Path
    A list of paths to check for old files.
    
    .Parameter MaxAgeDays
    Maximum age in days to ignore for when selecting files. Defaults to 90 days.
    
    .Example
    Get-OldFiles -Path c:\temp
    
    Get total size of files older than 3 months in C:\temp folder.
    #>
    param
    (
        [Parameter(Mandatory=$true, Position=1)]
        [array]$Path,

        [Parameter(Mandatory=$false, Position=2)]
        [int]$MaxAgeDays = 90
    )
    
    $Results = @()

    $cutoff = (Get-Date).AddDays(-$MaxAgeDays)
    
    foreach ($p in $Path)
    {
        $space = Get-ChildItem -Path $p -Recurse -Force |
            Where-Object { $_.LastWriteTime -lt $cutoff } |
            Measure-Object -Property Length -Sum |
            Select-Object -ExpandProperty Sum
        
        $Result = New-Object -TypeName psobject
        $Result | Add-Member -MemberType NoteProperty -Name 'Path' -Value $p
        $Result | Add-Member -MemberType NoteProperty -Name 'MB_Used' -Value $("{0:n1}" -f ($space/1MB))

        $Results += $Result
    }

    return $Results
}
<#
    PS C:\> Get-OldFiles -Path c:\temp
    Path            MB_Used
    ----            -------
    c:\temp         3,825.6

    PS C:\>
#>
#endregion
