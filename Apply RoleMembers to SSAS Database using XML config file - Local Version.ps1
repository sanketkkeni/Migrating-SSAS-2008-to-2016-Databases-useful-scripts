# Name: Apply RoleMembers to SSAS Database using XML config file.ps1
# Created by: Sanket Keni
# Date created: 08/29/2019
# Scope: ******
# Description: This PS Script is used to apply roles and member information on the SSAS Database from XML Config files. It is supposed to be run locally. 


########## High Level Inputs ##########
$SSASServerName = 'SSAS Instance 1'
$XMLconfigFile = 'C:\Files\SSAS DB1\SSAS DB1 DEV Roles.xml'
#######################################


Import-Module SqlServer


# Try to connect to the SSAS server
$SSASServer = New-Object Microsoft.AnalysisServices.Server
$SSASServer.Connect($SSASServerName)

# Object to store the result
$RolesFromServerObj = @()

# Get the SSAS databases and loop thru each of them
foreach ($DB in $SSASServer.Databases)
{
    # Get the SSAS database
    $SSASDatabase = $SSASServer.Databases.Item($DB.name)

    # Get the roles available within the SSAS database and loop thru each of them
    foreach ($Role in $SSASDatabase.Roles)
    {
        # Get the members within the role and loop thru each one of them
        foreach ($Member in $Role.Members)
        {
            # Create a new object that would store the database name, role name and member user name
            $ItemResult = New-Object System.Object
            $ItemResult | Add-Member -type NoteProperty -name DatabaseName -value $DB.Name
            $ItemResult | Add-Member -type NoteProperty -name RoleName -value $Role.Name
            $ItemResult | Add-Member -type NoteProperty -name Member -value $Member.Name

            # Put the item result and append it to the result object
            $RolesFromServerObj +=$ItemResult
        }
    }
}


[XML]$XML = get-content $XMLconfigFile
$RolesFromXMLObj = $XML.configuration.SecurityRoles.Member


Write-Host 'Following Roles should be added:'
#### Add following roles to SSAS Database ######
$RolesFromXMLObj | ForEach-Object {
	$currRole = $_.role
	$currMember = $_.member
	if(($RolesFromServerObj.RoleName -contains $currRole) -AND ($RolesFromServerObj.Member -contains $currMember)) {}
    else {
              Write-Host $currRole $currMember ##User needs to be added
			  Add-RoleMember -MemberName $currMember -Database $DB.Name -RoleName $currRole -Server $SSASServer

		 }
	}


Write-Host '
Following Roles should be removed:'
#### Remove following roles from SSAS Database ######
$RolesFromServerObj | ForEach-Object {
	$currRole = $_.RoleName
	$currMember = $_.Member
	if(($RolesFromXMLObj.role -contains $currRole) -AND ($RolesFromXMLObj.member -contains $currMember)) {}
    else {
              Write-Host $currRole $currMember ##User needs to be removed
		 }
	}



Write-Host '
Done'


