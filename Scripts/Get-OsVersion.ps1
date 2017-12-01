#region Get-OSVersion
Function Get-OSVersion
{
    <#
    .Synopsis
    Displays information about OS version on local and remote computers
    
    .Description
    Collect and display information about OS build number, OS name, OS architecture, and
    Windows install directory.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Example
    Get-OSVersion
    
    Get data from the local computer
    
    .Example
    Get-OSVersion -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    #>
    param
    (
        # Take an array as input so we can pipe a list of computers in
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string[]]$ComputerName = $env:computername
    )
    
    begin
    {
        # Create an array to hold our objects
        $AllMembers = @()
    }
    
    process
    {
        foreach ($target in $ComputerName)
        {
            # Make sure we can even talk to the target. If not, cancel this loop and move on
            if (!(Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue))
            {
                continue
            }
            
            # Get relevant memory info from WMI on the target computer
            $OSSpecs = Get-WmiObject -Class Win32_Operatingsystem -ComputerName $target |
                Select-Object WindowsDirectory,OSArchitecture,Caption,BuildNumber
            
            # Add info to a custom object
            $OSInfo = New-Object -TypeName PSObject
            $OSInfo | Add-Member -MemberType NoteProperty -Name ComputerName -Value $target
            $OSInfo | Add-Member -MemberType NoteProperty -Name OSName -Value $OSSpecs.Caption
            $OSInfo | Add-Member -MemberType NoteProperty -Name OSBuild -Value $OSSpecs.BuildNumber
            $OSInfo | Add-Member -MemberType NoteProperty -Name OSArch -Value $OSSpecs.OSArchitecture
            $OSInfo | Add-Member -MemberType NoteProperty -Name WinDir -Value $OSSpecs.WindowsDirectory
            
            # Add object to full array
            $AllMembers += $OSInfo
        }
    }
    
    end
    {    
        # Return collected data
        return $AllMembers
    }
}
<#
    Example Output:
    
    PS C:\> Get-OSVersion -ComputerName $(Get-ADComputer -Filter {enabled -eq 'True'}).Name | ft
    ComputerName OSName                                                 OSBuild OSArch WinDir
    ------------ ------                                                 ------- ------ ------
    RIGEL        Microsoft Windows Server 2016 Technical Preview 3      10514   64-bit C:\Windows
    SOL          Microsoft Windows Server 2012 R2 Datacenter            9600    64-bit C:\Windows
    APODIS       Microsoft Windows Server 2016 Technical Preview 3      10514   64-bit C:\Windows
    VYCANIS      Microsoft Windows Server 2016 Technical Preview 3      10514   64-bit C:\Windows
    SADATONI     Microsoft Windows Server 2016 Technical Preview 3      10514   64-bit C:\Windows
    DENEB        Microsoft Windows Server 2016 Technical Preview 3      10514   64-bit C:\Windows
    RANA         Microsoft Windows Server 2016 Technical Preview 3 Tuva 10514   64-bit C:\Windows
    POLONIUM     Microsoft Windows 10 Pro                               10586   64-bit C:\Windows
#>
#endregion
