<#
    Custom Functions to make common data data more easily readable or collectable
    than might otherwise be possible using existing tools and methods.
    
    Created 04/22/16
    
    Changelog:
        04/25/16 - v1.0.0.1
            Add Get-InstalledSoftware
            Add Get-FolderSize
            Add PS Help comments
            Convert to module via manifest file
        05/24/16 - v1.0.0.2
            Add Get-Password
                Extend number of special characters supported
        07/01/16 - v1.0.0.3
            Add Get-DFSRStats
        07/29/16 - v1.0.0.4
            Add Set-FutureRestart
            Add Get-LocalTime
        08/04/16
            Add Get-BLStatus
#>

#region Get-MemoryStats
Function Get-MemoryStats
{
    <#
    .Synopsis
    Displays information about memory usage on local and remote computers
    
    .Description
    Collect and display information such as free, used, and total memory. Additionally
    displays free and used memory as a percent of total.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Example
    Get-MemoryStats
    
    Get data from the local computer
    
    .Example
    Get-MemoryStats -ComputerName 'localhost','computer1','computer2'
    
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
        # Loop through each object in the input array
        foreach ($target in $ComputerName)
        {
            # Make sure we can even talk to the target. If not, cancel this loop and move on
            if (!(Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue))
            {
                continue
            }

            # Get relevant memory info from WMI on the target computer
            $MemorySpecs                = Get-WmiObject -Class Win32_Operatingsystem -ComputerName $target |
                Select-Object FreePhysicalMemory,TotalVisibleMemorySize
            
            # Create some variables using the data from the WMI query
            # When we're done manipulating them, we specifically cast them as float or int
            # to prevent PowerShell from treating them like strings for sorting or further
            # work with the dataset   
            $FreeMemory                 = $MemorySpecs.FreePhysicalMemory
            $TotalMemory                = $MemorySpecs.TotalVisibleMemorySize
            $UsedMemory                 = $TotalMemory - $FreeMemory
            [float]$FreeMemoryPercent   = "{0:N2}" -f (($FreeMemory / $TotalMemory) * 100)
            [float]$UsedMemoryPercent   = "{0:N2}" -f (100 - $FreeMemoryPercent)
            [int]$FreeMemory            = "{0:N0}" -f ($FreeMemory / 1kb)
            [int]$TotalMemory           = "{0:N0}" -f ($TotalMemory / 1kb)
            [int]$UsedMemory            = "{0:N0}" -f ($UsedMemory / 1kb)
            
            # Create and populate an object for the data
            $FreeAndTotal = New-Object -TypeName PSObject
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name ComputerName -Value $target
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name TotalMemory -Value $TotalMemory
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name FreeMemory -Value $FreeMemory
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name UsedMemory -Value $UsedMemory
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name FreeMemoryPercent -Value $FreeMemoryPercent
            $FreeAndTotal | Add-Member -MemberType NoteProperty -Name UsedMemoryPercent -Value $UsedMemoryPercent

            # Add object to the collection array
            $AllMembers += $FreeAndTotal
            
        }
    }
    
    end
    {    
        # Return the collection array
        Return $AllMembers
    }
}
<#    
    Example Output:
    
    PS C:\> Get-MemoryStats -ComputerName $(Get-ADComputer -Filter {enabled -eq 'True'}).Name | ft
    ComputerName TotalMemory FreeMemory UsedMemory FreeMemoryPercent UsedMemoryPercent
    ------------ ----------- ---------- ---------- ----------------- -----------------
    RIGEL                839        359        480             42.76             57.24
    SOL                 1871        865       1006             46.23             53.77
    APODIS               971        332        639             34.17             65.83
    VYCANIS            12279       5294       6985             43.11             56.89
    SADATONI             509        300        209             58.89             41.11
    DENEB               2777        765       2012             27.54             72.46
    RANA                 512        337        175             65.85             34.15
    POLONIUM           32709      25027       7682             76.51             23.49
#>
#endregion

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

#region Get-Uptime
function Get-Uptime
{
    <#
    .Synopsis
    Displays information about uptime on local and remote computers
    
    .Description
    Collect and display information about computer uptime calculated from data on
    the remote computer.
    
    .Parameter ComputerName
    A name, array, or comma-separated list of computers.
    
    .Example
    Get-Uptime
    
    Get data from the local computer
    
    .Example
    Get-Uptime -ComputerName 'localhost','computer1','computer2'
    
    Get data from multiple computers
    #>
    param
    (
        # Take an array as input so we can pipe a list of computers in
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [array]$ComputerName = @('localhost')
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
            $OSSpecs = Get-WmiObject -Class Win32_Operatingsystem -ComputerName $target
            
            # Convert LastBootUpTime into a useful DateTime object and Use it to calculate total uptime
            $LastBootTime   = $OSSpecs.ConvertToDateTime($OSSpecs.LastBootUpTime)
            $CurrentTime    = $OSSpecs.ConvertToDateTime($OSSpecs.LocalDateTime)
            $Uptime         = $CurrentTime - $LastBootTime
            
            # Convert these values to use leading zeroes for consistency
            [string]$Days       = $Uptime.Days
            [string]$Hours      = $Uptime.Hours
            [string]$Minutes    = $Uptime.Minutes
            [string]$Seconds    = $Uptime.Seconds
            $Hours              = $Hours.PadLeft(2,"0")
            $Minutes            = $Minutes.PadLeft(2,"0")
            $Seconds            = $Seconds.PadLeft(2,"0")
            $Uptime             = "$Days`.$Hours`:$Minutes`:$Seconds"
            
            # Convert LastBootUpTime to local time in case of time zone discrepancy
            # TODO: Test this more. It appears to have converted a local time into UTC
            <#
            if (($LastBootTime.AddHours(1) -))
            $LastBootTime       = $LastBootTime.ToLocalTime()
            #>
            
            # Create a custom object to store our data before returning it
            $TimeData           = New-Object -TypeName PSObject
            $TimeData | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Target
            $TimeData | Add-Member -MemberType NoteProperty -Name UpTime -Value $Uptime
            $TimeData | Add-Member -MemberType NoteProperty -Name LastBootTime -Value $LastBootTime
            
            # Add object to collection array
            $AllMembers += $TimeData
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
    
    PS C:\> Get-Uptime -ComputerName $(Get-ADComputer -Filter {enabled -eq 'True'}).Name | ft
    ComputerName UpTime      LastBootTime
    ------------ ------      ------------
    RIGEL        22.01:26:00 4/2/2016 6:45:04 PM
    SOL          0.16:47:24  4/24/2016 3:23:41 AM
    APODIS       4.04:03:51  4/20/2016 4:07:14 PM
    VYCANIS      22.01:33:23 4/2/2016 6:37:42 PM
    SADATONI     22.01:23:41 4/2/2016 6:47:24 PM
    DENEB        2.02:38:50  4/22/2016 5:32:15 PM
    RANA         22.01:21:33 4/2/2016 6:49:33 PM
    POLONIUM     2.01:33:15  4/22/2016 6:37:53 PM
#>
#endregion

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

        [parameter(
            Mandatory=$false
        )]
        [switch]$IncludeUpdates
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
        foreach($Computer in $ComputerName)
        {
            if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0))
            {
                continue
            }
            
            foreach($UninstallRegKey in $UninstallRegKeys)
            {
                try
                {
                    $HKLM   = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
                    $UninstallRef  = $HKLM.OpenSubKey($UninstallRegKey)
                    $Applications = $UninstallRef.GetSubKeyNames()
                }
                catch
                {
                    Write-Verbose "Failed to read $UninstallRegKey"
                    Continue
                }
                
                foreach ($App in $Applications)
                {
                    $AppRegistryKey             = $UninstallRegKey + "\\" + $App
                    $AppDetails                 = $HKLM.OpenSubKey($AppRegistryKey)
                    $AppUninstall               = $($AppDetails.GetValue("UninstallString"))

                    if ($AppUninstall -match "msiexec(.exe){0,1} \/[XIxi]{1}\{.*")
                    {
                        $AppGUID                = $AppUninstall -replace "msiexec(.exe){0,1} \/[XIxi]{1}\{","{"
                    }
                    else
                    {
                        $AppGUID                = ''
                    }
                    
                    $AppDisplayName             = $($AppDetails.GetValue("DisplayName"))
                    $AppVersion                 = $($AppDetails.GetValue("DisplayVersion"))
                    $AppPublisher               = $($AppDetails.GetValue("Publisher"))
                    $AppInstalledDate           = $($AppDetails.GetValue("InstallDate"))

                    if($UninstallRegKey -match "Wow6432Node")
                    {
                        $Softwarearchitecture   = "x86"
                    }
                    else
                    {
                        $Softwarearchitecture   = "x64"
                    }            
                    
                    if((!$AppDisplayName) -or (($AppDisplayName -match ".*KB[0-9]{7}.*") -and (!$IncludeUpdates)))
                    {
                        continue
                    }
                    
                    $OutputObj = New-Object -TypeName PSobject
                    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $AppDisplayName
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $AppVersion
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $AppPublisher
                    $OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value $AppInstalledDate
                    $OutputObj | Add-Member -MemberType NoteProperty -Name UninstallKey -Value $AppUninstall
                    $OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $AppGUID
                    $OutputObj | Add-Member -MemberType NoteProperty -Name SoftwareArchitecture -Value $Softwarearchitecture

                    $AllMembers += $OutputObj
                }
            }   
        }
    }

    end
    {
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
    
    <Output truncated to save space>
#>
#endregion

#region Get-FolderSize
function Get-FolderSize
{
    <#
    .Synopsis
    Gather total size of folders.
    
    .Description
    Recursively get total size of all files inside every folder path given. Limited by access
    permissions of running user. 
    
    .Parameter FolderPath
    A name, array, or comma-separated list of folder paths to calculate the size of.
    
    .Example
    Get-FolderSize
    
    Get total size of all files inside current path.
    
    .Example
    Get-FolderSize -Path c:\temp
    
    Get total size of all files into c:\temp
    
    .Example
    (ls c:\ -Attributes D).FullName | Get-FolderSize
    
    Get total size of all files within each folder returned by (ls c:\ -Attributes D)
    #>
    param
    (
        [parameter(
            ValueFromPipeline=$true
        )]
        [string[]]$Path = $(Get-Location).Path # The path to be measured
    )

    begin
    {
        # Create an array to store our pipeline object results
        $AllMembers = @()
    }

    process
    {
        # Create a float to store our file size total in bytes
        [float]$totalSize   = 0
        
        # Iterate through the array of paths submitted
        foreach ($folder in $Path)
        {
            # Get every file in the target path
            ForEach ($file in (Get-ChildItem $folder -Recurse -Attributes !D))
            {
                # Use measure object to get the byte size of each file and add
                # it to $totalSize
                $fileSize = Measure-Object -InputObject $file -Property length -Sum
                $totalSize += $fileSize.sum
            }
        }
        
        # Create and populate our custom object
        # TODO: Do we need to collect size three different ways? Maybe we can customize the object
        # based on input from user and just default to GB if not specified.
        $PathSum = New-Object -TypeName PSObject
        $PathSum | Add-Member -MemberType NoteProperty -Name Path -Value $folder
        $PathSum | Add-Member -MemberType NoteProperty -Name SizeInGB -Value ("{0:N2}" -f ($totalSize / 1GB))
        $PathSum | Add-Member -MemberType NoteProperty -Name SizeInMB -Value ("{0:N0}" -f ($totalSize / 1MB))
        $PathSum | Add-Member -MemberType NoteProperty -Name SizeInKB -Value ("{0:N0}" -f ($totalSize / 1KB))
        
        # Add custom object to array
        $AllMembers += $PathSum
    }
        
    end
    {
        # Ship that shit back to the user
        return $AllMembers
    }
}
<#
    Expected Output:
    
    PS C:\temp> Get-FolderSize
    
    Path    SizeInGB SizeInMB SizeInKB
    ----    -------- -------- --------
    C:\temp 2.69     2,752.32 2,818,380.25
#>
#endregion

#region Get-Password
function Get-Password
{
    <#
    .Synopsis
    Generate random passwords.
    
    .Description
    Generate random passwords. Length defaults to 12 characters. Special characters, numbers, and capital
    letters can be removed using switches.
    
    .Parameter PasswordLength
    An integer describing the number of characters to select for the password.
    
    .Parameter NoSpecialChars
    Switch disabling the use of special characters in the password.
    
    .Parameter NoCaps
    Switch disabling the use of capital letters in the password.
    
    .Parameter NoNumbers
    Switch disabling the use of numbers in the password. 
    
    .Example
    Get-Password
    
    Get a 12 chracter password including at least 1 of each of the following:
        - Numbers
        - Upper case letters
        - Lower case letters
        - Special characters
    
    .Example
    Get-Password -NoSpecialChars
    
    Get a 12 character password without special characters.
    
    .Example
    Get-Password -PasswordLength 24
    
    Get a 24 chracter password including at least 1 of each of the following:
        - Numbers
        - Upper case letters
        - Lower case letters
        - Special characters
    #>
    param
    (
        [int]$PasswordLength = 12,
        [switch]$NoSpecialChars,
        [switch]$NoCaps,
        [switch]$NoNumbers
    )
    
    <#
        Define charsets and match strings
        The method being used to choose random chars removes a char from the list when choosing it
        so lists are tripled. This is not the most secure method of generating a password because of
        the removal of these characters. Do not use this is true security is necessary
    #>
    $lowerChars = 'abcdefghijklmnopqrstuvwxyz'
    $lowerMatch = '[a-z]{1,}'
    $capitalChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $capitalMatch = '[A-Z]{1,}'
    $specialChars = '`~!@#$%^&*-+_=|:;<>,.?'
    $specialMatch = '[`~!@#$%^&*-+_=|:;<>,.?]{1,}'
    $numChars = '1234567890'
    $numMatch = '[0-9]{1,}'
    
    $pwdChars = $lowerChars
    $matchString = ".*$lowerMatch"
    
    # Create list of potential password chars and match strings
    if (!($NoCaps))
    {
        $pwdChars += $capitalChars
        $matchString += ".*$capitalMatch"
    }
    
    if (!($NoSpecialChars))
    {
        $pwdChars += $specialChars
        $matchString += ".*$specialMatch"
    }
    
    if (!($NoNumbers))
    {
        $pwdChars += $numChars
        $matchString += ".*$numMatch"
    }
    
    $matchString += '.*'
    
    # Create and check new passwords until match is valid
    while ($true)
    {
        $passwdString = -join ($pwdChars.ToCharArray() * 100 | Get-Random -Count $PasswordLength)
        
        if ($passwdString -match $matchString)
        {
            return $passwdString
        }
    }
}
<#
Expected output:

    PS C:\temp> Get-Password
    71s*Q#j3c2#G
    PS C:\temp> Get-Password -NoSpecialChars
    cYGjDJ6IhusZ
    PS C:\temp> Get-Password -PasswordLength 20
    TSJCBldFs4Rurs8!9RmN
#>
#endregion

#region Get-OldFiles
function Get-OldFiles
{
<#
    .Synopsis
    Display and reclaim used space in folders.
    
    .Description
    Gathers used space in folders based on minimum age. This data can be used to purge old files.
    
    .Parameter Admin
    Assuming user has admin rights, get space in C:\Windows\Temp.
    
    .Parameter MinAge
    Minimum age in months to search for when selecting files. Defaults to 3 months.
    
    .Example
    Get-TempSize
    
    Get total size of files older than 3 months in user's temp folder.
    #>
    param
    (
        [int]$MinAge = 3,
        [string]$Path = ".",
        [bool]$Delete
    )
    
    # look at temp files older than 3 months 
    $cutoff = (Get-Date).AddMonths(-$MinAge)
    
    if ($Delete)
    {
        # use an ordered hash table to store logging info 
        $sizes = [Ordered]@{}
         
        # find all files in both temp folders recursively 
        Get-ChildItem "$env:windir\temp", $env:temp -Recurse -Force -File |
        # calculate total size before cleanup 
        ForEach-Object { 
          $sizes['TotalSize'] += $_.Length 
          $_
        } |
        # take only outdated files 
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        # try to delete. Add retrieved file size only 
        # if the file could be deleted 
        ForEach-Object {
          try
          { 
            $fileSize = $_.Length
            # ATTENTION: REMOVE -WHATIF AT OWN RISK
            # WILL DELETE FILES AND RETRIEVE STORAGE SPACE
            # ONLY AFTER YOU REMOVED -WHATIF
            Remove-Item -Path $_.FullName -ErrorAction SilentlyContinue
            $sizes['Retrieved'] += $fileSize
          }
          catch {}
        }
         
         
        # turn bytes into MB 
        $Sizes['TotalSizeMB'] = [Math]::Round(($Sizes['TotalSize']/1MB), 1)
        $Sizes['RetrievedMB'] = [Math]::Round(($Sizes['Retrieved']/1MB), 1)
         
        New-Object -TypeName PSObject -Property $sizes
    }
    else
    {
        $space = Get-ChildItem "$Path" -Recurse -Force |
            Where-Object { $_.LastWriteTime -lt $cutoff } |
            Measure-Object -Property Length -Sum |
            Select-Object -ExpandProperty Sum
            
        return ("Space used in $Path`: {0:n1} MB" -f ($space/1MB))
    }
}
<#
    PS C:\> Get-TempSize
    Space used in C:\Users\user1\AppData\Local\Temp: 25.4 MB
#>
#endregion

#region Get-DiskSize
function Get-DiskSize
{
    <#
        .Synopsis
        Display free and total space on remote and local logical disks.
        
        .Description
        Display free and total space on all remote and local logical disks using WMI.
        
        .Parameter ComputerName
        Name of target computer. Defaults to localhost.
        
        .Example
        Get-DiskSize
        
        Get free and total space in GB on local computer.
    #>
    param
    (
        [string]$ComputerName = $env:computername
    )
    
    $Disks = Get-WmiObject -Class win32_logicaldisk -ComputerName $ComputerName
    
    foreach ($disk in $Disks)
    {
        $disk.FreeSpace = "{0:N2}" -f ($disk.FreeSpace / 1gb)
        $disk.size = "{0:N2}" -f ($disk.Size / 1gb)
    }
    
    return $Disks
}
<#
    PS C:\> Get-DiskSize 
                     
    DeviceID     : C:    
    DriveType    : 3     
    ProviderName :       
    FreeSpace    : 42    
    Size         : 232   
    VolumeName   : OSDisk
                         
    DeviceID     : D:    
    DriveType    : 3     
    ProviderName :       
    FreeSpace    : 302   
    Size         : 466   
    VolumeName   : Data  
    
    PS C:\>
                     
#>
#endregion

#region Get-DFSRStats
function Get-DFSRStats
{
    <#
        .Synopsis
        Gather DFSR health stats from WMI.
        
        .Description
        Collect statistics about DFSR health including staging space in use and replication updates dropped.
        
        .Parameter ComputerName
        Name of target computer. Defaults to localhost.
        
        .Parameter ReplicationGroupName
        String to search for in replication group name. This can contain wildcards.
        
        .Example
        Get-DFSRStats -ComputerName dfs-01.domain.com
        
        Get formatted DFSR stats from specified DFS server.
    #>
    param
    (
        [string]$ComputerName = "$env:ComputerName",
        [string]$ReplicationGroupName
    )
    
    function Get-Size($iNum)
    {
        if (($iNum / 1tb) -gt 1)
        {
            $Formatted = "{0:N2}" -f ($iNum / 1tb)
            $Final = $Formatted + " TB"
        }
        elseif (($iNum / 1gb) -gt 1)
        {
            $Formatted = "{0:N2}" -f ($iNum / 1gb)
            $Final = $Formatted + " GB"
        }
        else
        {
            $Formatted = "{0:N2}" -f ($iNum / 1mb)
            $Final = $Formatted + " MB"
        }
        
        return $Final
    }
    
    $ReplicationGroups = Get-CimInstance -ClassName 'Win32_PerfFormattedData_dfsr_DFSReplicatedFolders'`
        -ComputerName $computerName
    
    $RepGroups = @()
    
    foreach ($Group in $ReplicationGroups)
    {
        $DFSRObj = New-Object -TypeName PSObject
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ComputerName' -Value $($Group.PSComputerName)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'GroupName' -Value $($Group.Name)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ConflictSpaceGenerated' -Value (Get-Size -iNum $Group.ConflictBytesGenerated)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ConflictSpaceCleaned' -Value (Get-Size -iNum $Group.ConflictBytesCleanedup)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'ConflictSpaceUsed' -Value (Get-Size -iNum $Group.ConflictSpaceInUse)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'DeletedSpaceGenerated' -Value (Get-Size -iNum $Group.DeletedBytesGenerated)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'DeletedSpaceCleaned' -Value (Get-Size -iNum $Group.DeletedBytesCleanedup)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'DeletedSpaceUsed' -Value (Get-Size -iNum $Group.DeletedSpaceInUse)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'StagingSpaceGenerated' -Value (Get-Size -iNum $Group.StagingBytesGenerated)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'StagingSpaceCleaned' -Value (Get-Size -iNum $Group.StagingBytesCleanedup)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'StagingSpaceUsed' -Value (Get-Size -iNum $Group.StagingSpaceInUse)
        $DFSRObj | Add-Member -MemberType NoteProperty -Name 'UpdatesDropped' -Value $($Group.UpdatesDropped)
        
        $RepGroups += $DFSRObj
    }
    
    if (!($ReplicationGroupName))
    {
        return $RepGroups
    }
    else
    {
        return $RepGroups | Where-Object {$_.GroupName -like $ReplicationGroupName}
    }
}
<#
    C:\> Get-DFSRStats
    
    ComputerName           : dfs-01.domain.com
    GroupName              : ReplGroup-{z69tb0ym-576v-a8c3-1rsc-7qzjnkqgei8h}
    ConflictSpaceGenerated : 8.17 MB
    ConflictSpaceCleaned   : 0.00 MB
    ConflictSpaceUsed      : 8.17 MB
    DeletedSpaceGenerated  : 3.12 GB
    DeletedSpaceCleaned    : 0.00 MB
    DeletedSpaceUsed       : 3.12 GB
    StagingSpaceGenerated  : 1.09 TB
    StagingSpaceCleaned    : 1.01 TB
    StagingSpaceUsed       : 159.76 GB
    UpdatesDropped         : 0
#>
#endregion

#region Get-LocalTime
Function Get-LocalTime($UTCTime)
{
    <#
    .Synopsis
    Convert UTC to local time.
    
    .Description
    Using local timezone data, convert UTC/GMT time to local time.
    
    .Parameter UTCTime
    A UTC datetime object or string which PowerShell can interpret as a datetime.
    
    .Example
    Get-LocalTime -UTCTime "21:00 07/30/16"
    
    Get UTC time converted to local time.
    #>
    $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
    $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
    $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    Return $LocalTime
}
<#
    PS C:\> Get-LocalTime -UTCTime "21:00 07/30/16"
    
    Saturday, July 30, 2016 4:00:00 PM
    PS C:\>
#>
#endregion

#region Set-FutureRestart
function Set-FutureRestart
{
    <#
    .Synopsis
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
#region Invoke-RoboCopy
function Invoke-Robocopy
{
    <#
    .Synopsis
    PowerShell wrapper for RoboCopy.
    
    .Description
    Provides switches and simple syntax including Intellisense to simplify PowerShell usage.
    
    .Parameter Source
    The source location.
    
    .Parameter Destination
    The destination location.
    
    .Parameter Filter
    A simple filter for the files/folders within the source. Can be used with wildcards.
    
    .Parameter LogLocation
    The path and filename where robocopy logs should be written.

    .Parameter Tee
    Output to console window, as well as the log file.
    
    .Parameter Recurse
    Copy subdirectories, including Empty ones.
    
    .Parameter Open
    Open destination directory after transfer is completed.
    
    .Parameter ExcludeOld
    Exclude files and folders that older than those in the destination.
    
    .Parameter MultiThread
    Run multiple concurrent transfer threads.
    
    .Parameter CopyAll
    Copy all file and folder attributes.
    
    .Parameter RunHours
    Hour range in which transfers are to be performed.
    
    .Parameter PerFile
    Check run hours between each individual file.
    
    .Parameter Retry
    Number of time to retry a failed file copy before skipping it.
    
    .Parameter Mirror
    Mirror a directory tree.
    
    .Parameter Move
    Delete files from the source.
    
    .Parameter List
    Only list files in source directory. Do not change, copy, delete, or timestamp anything.
    
    .Parameter Create
    Create directory structure and zero length files in destination.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user
    
    Copy all files from the source folder to the destination folder.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -Filter *work*
    
    Copy all files with "work" in the name from the source to the destination.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -RunHour 1900-0600 -PerFile
    
    Copy all files between 7:00pm and 6:00am. Check time between every file.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -ExcludeOld
    
    Only copy files that are new or have changed.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -List
    
    List files that would be copied.
    
    .Example
    Invoke-RoboCopy -Source C:\MyFiles -Destination \\server\user -LogLocation C:\Temp\transfer.log -Tee
    
    Copy files while writing a log. Also output log to console.
    #>
    param 
    (
        [String]
        [Parameter(Mandatory)]
        $Source,
        
        [String]
        [Parameter(Mandatory)]
        $Destination,
        
        [String]
        $Filter = '*',
        
        [String]
        $LogLocation,
        
        [Switch]
        $Tee,
        
        [Switch]
        $Recurse,
        
        [Switch]
        $Open,
        
        [Switch]
        $ExcludeOld,
        
        [int]
        $MultiThread,
        
        [Switch]
        $CopyAll,
        
        [String]
        $RunHours,
        
        [Switch]
        $PerFile,
        
        [Int]
        $Retry = 5,
        
        [Switch]
        $Mirror,
        
        [Switch]
        $Move,
        
        [Switch]
        $List,
        
        [Switch]
        $Create
    )
    
    #**************************
    # Set various switches here
    
    # Recurse, keeping empty directories
    if ($Recurse)
    {
        $DoRecurse = '/E '
    }
    else
    {
        $DoRecurse = $null
    }
    
    #Exclude old files
    if ($ExcludeOld)
    {
        $DoExclude = '/XO '
    }
    else
    {
        $DoExclude = $null
    }
    
    #Logging
    if ($LogLocation)
    {
        $DoLogging = "/LOG:`"$LogLocation`" "
    }
    else
    {
        $DoLogging = $null
    }
    
    #Log Teeing
    if ($Tee)
    {
        $DoTee = '/TEE '
    }
    else
    {
        $DoTee = $null
    }
    
    #Multithreading
    if ($MultiThread)
    {
        $DoMultithread = "/MT:$MultiThread "
    }
    else
    {
        $DoMultithread = $null
    }
    
    #Copy all settings
    if ($CopyAll)
    {
        $DoCopyAll = '/COPYALL '
    }
    else
    {
        $DoCopyAll = $null
    }
    
    #Run hours
    if ($RunHours)
    {
        $DoRunHour = "/RH:`"$RunHours`" "
    }
    else
    {
        $DoRunHour = $null
    }
    
    #Check run hours per file
    if ($PerFile)
    {
        $DoPerFile = '/PF '
    }
    else
    {
        $DoPerFile = $null
    }
    
    #Create
    if ($Create)
    {
        $DoCreate = '/CREATE '
    }
    else
    {
        $DoCreate = $null
    }
    
    #List
    if ($List)
    {
        $DoList = '/L '
    }
    else
    {
        $DoList = $null
    }
    
    #Move
    if ($Move)
    {
        $DoMove = '/MOVE '
    }
    else
    {
        $DoMove = $null
    }
    
    #Mirror
    if ($Mirror)
    {
        $DoMirror = '/MIR '
    }
    else
    {
        $DoMirror = $null
    }
    
    #**************************
    
    #Populate arguments string
    $RoboCopyArgs = '"$Source" '
    $RoboCopyArgs += '"$Destination" '
    $RoboCopyArgs += '"$Filter" '
    $RoboCopyArgs += '$DoRecurse '
    $RoboCopyArgs += '$DoLogging '
    $RoboCopyArgs += '$DoTee '
    $RoboCopyArgs += '$DoExclude '
    $RoboCopyArgs += '$DoMultithread '
    $RoboCopyArgs += '$DoCopyAll '
    $RoboCopyArgs += '$DoRunHour '
    $RoboCopyArgs += '$DoPerFile '
    $RoboCopyArgs += '$DoCreate '
    $RoboCopyArgs += '$DoList '
    $RoboCopyArgs += '$DoMove '
    $RoboCopyArgs += '$DoMirror '
    $RoboCopyArgs += '/R:$Retry'
    
    #Expand variable encapsulated in single quotes
    $RoboCopyArgs = $ExecutionContext.InvokeCommand.ExpandString($RoboCopyArgs)
    
    #Begin the robocopy job
    Start-Process -FilePath 'robocopy.exe' -ArgumentList $RoboCopyArgs -NoNewWindow -Wait
       
    if ($Open)
    {
        explorer.exe $Destination
    }
}
#endregion