# Get-Command -Module PowerShellGet
Find-Module | Where Name -like '*Web*'


Install-Module -Name xSqlPs
Install-Module -Name xDSCResourceDesigner
Install-Module -Name xWebAdministration
Install-Module -Name xOneGet

Install-Module -Name cWindowsOS

# Install-Module -Name ShowDscResourceModule  

# Get-Command -Module OneGet

Get-DSCResource -Name xOneGet


