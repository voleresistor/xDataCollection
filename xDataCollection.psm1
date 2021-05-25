<#
    Custom Functions to make common data data more easily readable or collectable
    than might otherwise be possible using existing tools and methods.
    
    Created 04/22/2016
    Updated 12/01/2017
            01/06/2020
                Add Get-UpgradeHistory
                Replace usage of Get-WmiObject with Get-CimInstance for compatibility with PowerShell 7
            03/04/2020
                Rewrite to meet PowerShell style guide recommendations
                Add code to load private functions that won't be exported
                Add supported PSEditions to manifest
#>

# ===================
# Internal Functions
# Not for export
# ===================
foreach ($ScriptFile in Get-ChildItem -Path "$PSScriptRoot\Scripts\Private" -Filter *.ps1) {
    . $ScriptFile.FullName
}

# Load each script in the Scripts folder. Individual functions are easier to maintain as scripts rather than
# all piled up in here.
foreach ($ScriptFile in Get-ChildItem -Path "$PSScriptRoot\Scripts" -Filter *.ps1) {
    . $ScriptFile.FullName
}

#Export-ModuleMember -Function *