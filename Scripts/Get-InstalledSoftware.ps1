#region Get-InstalledSoftware
function Get-InstalledSoftware
{
    <#
    .Synopsis
    Displays information about installed software on local and remote computers.
    
    .Description
    Collect and display information about installed software on local and remote computers.
    Gathers AppName, AppVersion, AppVendor, Install Date, Uninstall Key, and AppGUID.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Parameter IncludeUpdates
    A switch which enables inclusion of removable software updates in the list of software.

    .Parameter ProductName
    Name of product to search for.

    .Parameter ProductGuid
    GUID to search for.
    
    .Example
    Get-InstalledSoftware
    
    Get data from the local computer
    
    .Example
    Get-InstalledSoftware -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    
    .Example
    Get-InstalledSoftware -Computername computer1 -IncludeUpdates
    
    Get information about installed apps, including updates, from a remote computer
    #>
    param
    (
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string[]]$ComputerName = $env:computername,

        [parameter(Mandatory=$false)]
        [switch]$IncludeUpdates,

        [parameter(Mandatory=$false)]
        [string]$ProductName,

        [parameter(Mandatory=$false)]
        [string]$ProductGUID
    )
           
    begin
    {
        $UninstallRegKeys=
        @(
            "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
            "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
        )
        
        $AllMembers = @()
    }
                
    process
    {
        #Cycle through list of computers
        foreach($Computer in $ComputerName)
        {
            if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0))
            {
                continue
            }
            
            #Gather data based on each reg key
            foreach($UninstallRegKey in $UninstallRegKeys)
            {
                try
                {
                    $HKLM = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer)
                    $UninstallRef = $HKLM.OpenSubKey($UninstallRegKey)
                    $Applications = $UninstallRef.GetSubKeyNames()
                }
                catch
                {
                    Write-Verbose "Failed to read $UninstallRegKey"
                    Continue
                }
                
                #Populate app data
                foreach ($App in $Applications)
                {
                    $AppRegistryKey = $UninstallRegKey + "\\" + $App
                    $AppDetails = $HKLM.OpenSubKey($AppRegistryKey)

                    #Skip this object if there's no display name or it's an update and we aren't including them
                    if((!$($AppDetails.GetValue("DisplayName"))) -or (($($AppDetails.GetValue("DisplayName")) -match ".*KB[0-9]{7}.*") -and (!$IncludeUpdates)))
                    {
                        continue
                    }

                    #Match ProductName if provided
                    if ($ProductName -and !($($AppDetails.GetValue("DisplayName")) -match $ProductName))
                    {
                        continue
                    }

                    #Match ProductGUID if provided
                    if ($ProductGUID -and !($($AppDetails.GetValue("UninstallString")) -match $ProductGUID))
                    {
                        continue
                    }

                    #Create the object
                    $OutputObj = New-Object -TypeName PSobject
                    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()

                    #Begin populating the object
                    #Start by gathering the easy data
                    $OutputObj | Add-Member -MemberType NoteProperty -Name UninstallKey -Value $($AppDetails.GetValue("UninstallString"))
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $($AppDetails.GetValue("DisplayName"))
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $($AppDetails.GetValue("DisplayVersion"))
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $($AppDetails.GetValue("Publisher"))

                    #Extract the GUID from the MSI uninstall key
                    if ($($AppDetails.GetValue("UninstallString")) -match "msiexec(.exe){0,1} \/[XIxi]{1}\{.*")
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $($($AppDetails.GetValue("UninstallString")) -replace "msiexec(.exe){0,1} \/[XIxi]{1}\{","{")
                    }
                    else
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value ''
                    }

                    #Build a human readable date string
                    $RawDate = $AppDetails.GetValue("InstallDate")

                    if ($RawDate)
                    {
                        $RawYear = ($RawDate -split "[0-9]{4}$")[0]
                        $RawDM = ($RawDate -split "^[0-9]{4}")[1]
                        $RawMonth = ($RawDM -split "[0-9]{2}$")[0]
                        $RawDay = ($RawDM -split "^[0-9]{2}")[1]
                    
                        [datetime]$FormattedDate = "$RawMonth/$RawDay/$RawYear"
                        $OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value $($FormattedDate.ToShortDateString())
                    }
                    else
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value ''
                    }

                    #Determine if app is 64/32 bit. This assumes that all clients are 64 bit
                    if($UninstallRegKey -match "Wow6432Node")
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name SoftwareArchitecture -Value 'x86'
                    }
                    else
                    {
                        $OutputObj | Add-Member -MemberType NoteProperty -Name SoftwareArchitecture -Value 'x64'
                    }

                    $AllMembers += $OutputObj
                }   
            }
        }
    }
                
    end
    {
        #Return the data we discovered
        return $AllMembers
    }
}
<#
    Example Output:
    
    PS C:\> Get-InstalledSoftware -IncludeUpdates

    ComputerName         : localhost
    AppName              : CutePDF Writer 3.0
    AppVersion           :  3.0
    AppVendor            : CutePDF.com
    InstalledDate        :
    UninstallKey         : C:\Program Files (x86)\Acro Software\CutePDF Writer\Setup64.exe /uninstall
    AppGUID              :
    SoftwareArchitecture : x64

    ComputerName         : localhost
    AppName              : Microsoft Visual C++ 2005 Redistributable (x64)
    AppVersion           : 8.0.56336
    AppVendor            : Microsoft Corporation
    InstalledDate        : 20160309
    UninstallKey         : MsiExec.exe /X{071c9b48-7c32-4621-a0ac-3f809523288f}
    AppGUID              : {071c9b48-7c32-4621-a0ac-3f809523288f}
    SoftwareArchitecture : x64
    
    <Output truncated>
#>
#endregion
