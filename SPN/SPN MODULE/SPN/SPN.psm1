<#
# AUTHOR  : Victor Ashiedu
# WEBSITE : iTechguides.com
# BLOG    : iTechguides.com/blog
# CREATED : 26-02-2015 
# UPDATED : 26-02-2015 
# COMMENT : SPN PowerShell modules contains a number of functions to manage
#			SPNs (ServicePrincipalName). The module contains three functions:
#			Get-SPN: List SPNs in a Service Account
#			Add-SPN: Adds new SPNs to a Service Account
#			Remove-SPN: Removes SPNs from a Service Account
#>

Function Get-SPN {

<#
.SYNOPSIS
	Get-SPN PowerShell function list the SPNs (ServicePrincipalName) that exisits for a specified Service Account. 
	
.DESCRIPTION
	The Get-SPN advanced PowerShell function retrives ServicePrincipalNames that exisit for a specified Service Account	
	
.PARAMETER ServiceAccountName
	Specifies the Active Directory Service Account to retrieve SPN.  
		 
.PARAMETER Credential
	Specifies credential that runs the Function. 
.PARAMETER Server
	Specifies the Domain Controler to query. This is required in W2K3 Domains where one DC
	has Active Directory web services installed. It is also useful if you want to query a 
	Domain controller in another domain. 
.EXAMPLE
	To get all SPNs registered in the service account called SPN_Example:	
	PS C:\>Get-SPN -ServiceAccountName SPN_Example -Credential domain\domain_account -Server ADServer_name
#>

[CmdletBinding(DefaultParameterSetName='ServiceAccountName')]
PARAM
(		
		[Parameter(Mandatory=$true,Position=0,ParameterSetName='ServiceAccountName')]
	    [String[]]$ServiceAccountName,
		[Parameter(Mandatory=$false,Position=1,ParameterSetName='ServiceAccountName')]
		[String]$Credential,
		[Parameter(Mandatory=$false,Position=2,ParameterSetName='ServiceAccountName')]
		[String]$Server		
)

BEGIN {
If ($Credential) {$Cred = Get-Credential $Credential }

}

PROCESS
{
Write-Host "Importing ActiveDirectory Modules." -ForegroundColor Cyan
Import-Module ActiveDirectory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

ForEach ($SAM in $ServiceAccountName)
{
Write-Host "Searching for $ServiceAccountName in Active Directory " -ForegroundColor Yellow
If ($Credential) 
{

Try {
$dn = (Get-ADUser -Identity $SAM -server $Server -ErrorAction Stop).DistinguishedName
}
Catch [Exception]
{
Write-Host "$($_.Exception.Message) Please resolve the error and try again " -ForegroundColor Red
Break
}

$Result = Get-ADUser -LDAPFilter "(SamAccountname=$SAM)" -Properties name, serviceprincipalname `
-server $Server -Credential $Cred -ErrorAction Stop | 
Select-Object @{Label = "Service Principal Names";Expression = {$_.serviceprincipalname}} | 
Select-Object -ExpandProperty "Service Principal Names"

If ($Result) {
Write-host " " #adds a space before the line below
Write-host "The Service Principal names found in $SAM are listed below: " -ForegroundColor Yellow 
Write-host "" #adds a space after the line above
$Result 
Write-host "" #adds a space after the result
}

Else 
{
Write-host " " #adds a space before the line below
Write-host "No Service Principal name found in $SAM " -ForegroundColor Red  
Write-host " " #adds a space before the line below
} 

}

Else
{

Try {
$dn = (Get-ADUser -Identity $SAM -server $Server -ErrorAction Stop).DistinguishedName
}
Catch [Exception]
{
Write-Host "$($_.Exception.Message) Please resolve the error and try again " -ForegroundColor Red
Break
}

$Result = Get-ADUser -LDAPFilter "(SamAccountname=$SAM)" -Properties name, serviceprincipalname -server $Server -ErrorAction Stop | 
Select-Object @{Label = "Service Principal Names";Expression = {$_.serviceprincipalname}} | 
Select-Object -ExpandProperty "Service Principal Names"

If ($Result) {
Write-host " " #adds a space before the line below
Write-host "The Service Principal names found in $SAM are listed below: " -ForegroundColor Yellow 
Write-host "" #adds a space after the line above
$Result 
Write-host "" #adds a space after the result
}

Else 
{
Write-host " " #adds a space before the line below
Write-host "No Service Principal name found in $SAM " -ForegroundColor Red  
Write-host " " #adds a space before the line below
}

}

}

}

END {}

}


Function Add-SPN {

<#
.SYNOPSIS
	Add-SPN PowerShell function adds SPNs (ServicePrincipalName) to a specified Service Account. 
	
.DESCRIPTION
	The Add-SPN advanced PowerShell function adds SPNs (ServicePrincipalName) to a specified Service Account	
	
.PARAMETER ServiceAccountName
	Specifies the Active Directory Service Account to retrieve SPN.  
		 
.PARAMETER Credential
	Specifies credential that runs the Function. 
.PARAMETER Server
	Specifies the Domain Controler to query. This is required in W2K3 Domains where one DC
	has Active Directory web services installed. It is also useful if you want to query a 
	Domain controller in another domain. 
.EXAMPLE
	To add an SPN called HTTP/test.domain.co.uk to a service account with samaccountname User.Example, run the command below:	
	PS C:\> Add-SPN -ServiceAccountName User.Example -SPNs HTTP/test.domain.co.uk -Credential domain\user_name -Server ADServer_Nam
#>

[CmdletBinding(DefaultParameterSetName='ServiceAccountName')]
PARAM
(		
		[Parameter(Mandatory=$true,Position=0,ParameterSetName='ServiceAccountName')]
	    [String]$ServiceAccountName,
		[Parameter(Mandatory=$true,Position=1,ParameterSetName='ServiceAccountName')]
		[String[]]$SPNs,
		[Parameter(Mandatory=$true,Position=2,ParameterSetName='ServiceAccountName')]
		[String]$Credential,
		[Parameter(Mandatory=$false,Position=3,ParameterSetName='ServiceAccountName')]
		[String]$Server		
)

BEGIN {
If ($Credential) {$Cred = Get-Credential $Credential }

}
#amend parts of the process here to reflect the Add-SPN function. Delete the second process when done
PROCESS
{
Write-Host "Importing ActiveDirectory Modules." -ForegroundColor Cyan
Import-Module ActiveDirectory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Write-Host "Searching for $ServiceAccountName in Active Directory " -ForegroundColor Yellow
Try {
$dn = (Get-ADUser -Identity $ServiceAccountName -server $Server -ErrorAction Stop).DistinguishedName
}
Catch [Exception]
{
Write-Host "$($_.Exception.Message) Please check the name and try again " -ForegroundColor Red
Break
}

ForEach ($SPN in $SPNs)
{

##########################################################################
#Confirm whether SPN exists - If it exist, drop an info and Break
##########################################################################

$Result = Get-ADObject -LDAPFilter "(SamAccountname=$ServiceAccountName)" -Properties serviceprincipalname -server $Server -Credential $Cred |
Where-Object {$_.serviceprincipalname -eq $SPN } |  Select-Object serviceprincipalname
If (!$Result)
{
Write-Host "Adding $SPN to $ServiceAccountName." -ForegroundColor Yellow
If ($Server)
{
Try {
Set-ADObject -Identity $dn -add @{serviceprincipalname=$SPN} -Server $Server `
-Credential $Cred -ErrorVariable SPNerror -ErrorAction SilentlyContinue
}
Catch [exception]
{Write-Host "An error occured while modifying $ServiceAccountName. Error details: $($_.Exception.Message) " -ForegroundColor Red }
If ($SPNerror.Count -eq '0'){ Write-Host "$SPN added successfully to $ServiceAccountName" -ForegroundColor Magenta }
}
Else
{
Try {
Set-ADObject -Identity $dn -add @{serviceprincipalname=$SPN} `
-Credential $Cred -ErrorVariable SPNerror -ErrorAction SilentlyContinue
}
Catch [exception]
{Write-Host "An error occured while modifying $ServiceAccountName. Error details: $($_.Exception.Message) " -ForegroundColor Red }

If ($SPNerror.Count -eq '0') { Write-Host "$SPN added successfully to $ServiceAccountName" -ForegroundColor Magenta }

}
}
#closing If ($Result)
Else
{
Write-Host "The SPN, $SPN is already registered in $ServiceAccountName. " -ForegroundColor Red

}

}



}


END {}

}

Function Remove-SPN {

<#
.SYNOPSIS
	Remove-SPN PowerShell function removes SPNs (ServicePrincipalName) to a specified Service Account. 
	
.DESCRIPTION
	The Remove-SPN advanced PowerShell function removes SPNs (ServicePrincipalName) to a specified Service Account	
	
.PARAMETER ServiceAccountName
	Specifies the Active Directory Service Account to remove SPNs from.  
		 
.PARAMETER Credential
	Specifies credential that runs the Function. 
.PARAMETER Server
	Specifies the Domain Controler to query. This is required in W2K3 Domains where one DC
	has Active Directory web services installed. It is also useful if you want to query a 
	Domain controller in another trusted domain. 
.EXAMPLE
	To remove an SPN called HTTP/test.domain.co.uk to a service account with samaccountname User.Example, run the command below:	
	PS C:\> Remove-SPN -ServiceAccountName User.Example -SPNs HTTP/test.domain.co.uk -Credential domain\user_name -Server ADServer_Nam	
#>

[CmdletBinding(DefaultParameterSetName='ServiceAccountName')]
PARAM
(		
		[Parameter(Mandatory=$true,Position=0,ParameterSetName='ServiceAccountName')]
	    [String]$ServiceAccountName,
		[Parameter(Mandatory=$true,Position=1,ParameterSetName='ServiceAccountName')]
		[String[]]$SPNs,
		[Parameter(Mandatory=$true,Position=2,ParameterSetName='ServiceAccountName')]
		[String]$Credential,
		[Parameter(Mandatory=$false,Position=3,ParameterSetName='ServiceAccountName')]
		[String]$Server		
)

BEGIN {
If ($Credential) {$Cred = Get-Credential $Credential }

}

PROCESS
{
Write-Host "Importing ActiveDirectory Modules." -ForegroundColor Cyan
Import-Module ActiveDirectory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Write-Host "Searching for $ServiceAccountName in Active Directory " -ForegroundColor Yellow
Try {
$dn = (Get-ADUser -Identity $ServiceAccountName -server $Server -ErrorAction Stop).DistinguishedName
}
Catch [Exception]
{
Write-Host "$($_.Exception.Message) Please check the name and try again " -ForegroundColor Red
Break
}

ForEach ($SPN in $SPNs)
{

##########################################################################
#Confirm whether SPN exists - If it does not exist, drop an info and Break
##########################################################################

$Result = Get-ADObject -LDAPFilter "(SamAccountname=$ServiceAccountName)" -Properties serviceprincipalname -server $Server -Credential $Cred |
Where-Object {$_.serviceprincipalname -eq $SPN } |  Select-Object serviceprincipalname
If ($Result)
{
Write-Host "Removing $SPN from $ServiceAccountName." -ForegroundColor Yellow
If ($Server)
{
Try {
Set-ADObject -Identity $dn -remove @{serviceprincipalname=$SPN} -Server $Server `
-Credential $Cred -ErrorVariable SPNerror -ErrorAction SilentlyContinue
}
Catch [exception]
{Write-Host "An error occured while modifying $ServiceAccountName. Error details: $($_.Exception.Message) " -ForegroundColor Red }
If ($SPNerror.Count -eq '0'){ Write-Host "$SPN removed successfully from $ServiceAccountName" -ForegroundColor Magenta }
}
Else
{
Try {
Set-ADObject -Identity $dn -remove @{serviceprincipalname=$SPN} `
-Credential $Cred -ErrorVariable SPNerror -ErrorAction SilentlyContinue
}
Catch [exception]
{Write-Host "An error occured while modifying $ServiceAccountName. Error details: $($_.Exception.Message) " -ForegroundColor Red }

If ($SPNerror.Count -eq '0') { Write-Host "$SPN removed successfully to $ServiceAccountName" -ForegroundColor Magenta }

}
}
#closing If ($Result)
Else
{
Write-Host "The SPN, $SPN is not registered in $ServiceAccountName. " -ForegroundColor Red

}

}



}

END {}

}

