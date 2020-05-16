# Name: Apply RoleMembers to SSAS Database using XML config file.ps1
# Created by: Sanket Keni
# Date created: 08/29/2019
# Scope: ******
# Description: This PS Script is used to apply roles and member information on the SSAS Database from XML Config files. It is supposed to be used as a Step Template in Octopus


########## High Level Inputs ##########
$SSASServerName = $OctopusParameters["st-SSASTargetServer"]
$DepolyedPath = $OctopusParameters["Octopus.Action[$PackageDeploymentStep].Output.Package.InstallationDirectoryPath"]
$Environment = $OctopusParameters["st-Environment"]
# $XMLconfigFile = 'C:\Files\SSAS DB1\SSAS DB1 DEV Roles.xml'
#######################################


Import-Module SqlServer


# Try to connect to the SSAS server
$SSASServer = New-Object Microsoft.AnalysisServices.Server
$SSASServer.Connect($SSASServerName)

# Variable Pointing to XML Config file Directory
$XMLconfigFileDir = $DepolyedPath + '\' + $SSASServer.Databases.name + '\' + $SSASServer.Databases.name

# XML Config Full File Path
$XMLconfigFile = $XMLconfigFileDir + '\ConfigRoles.' + $Environment + '.xml'

# Validate if the file exists
if (-Not [System.IO.File]::Exists($XMLconfigFile)) {
	Write-Host 'The following config file not found:' $XMLconfigFile
	EXIT 1
}

Write-Host 'Using the config file to set roles:' $XMLconfigFile

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

# Load the XML Config file
[XML]$XML = get-content $XMLconfigFile
$RolesFromXMLObj = $XML.configuration.SecurityRoles.Member


Write-Host 'Following Roles should be added:'
#### Add following roles to SSAS Database ######
$RolesFromXMLObj | ForEach-Object {
	$currRole = $_.role
	$currMember = $_.member
	if(($RolesFromServerObj.RoleName -contains $currRole) -AND ($RolesFromServerObj.Member -contains $currMember)) {}
    else {
			  Add-RoleMember -MemberName $currMember -Database $DB.Name -RoleName $currRole -Server $SSASServer
			  Write-Host 'Member:' $currMember 'was added to the role:' $currRole
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
    		  Remove-RoleMember -MemberName $currMember -Database $DB.Name -RoleName $currRole -Server $SSASServer
              Write-Host 'Member:' $currMember 'was removed from the role:' $currRole
		 }
	}



Write-Host '
Done'


