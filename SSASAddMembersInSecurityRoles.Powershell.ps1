# Name: Add Members in SSAS Database Roles
# Created by: Sanket Keni
# Date created: 08/22/2019
# Scope: ******
# Description: This PS Script is used to add a member to Roles on SSAS Database. This is required as the members will be different in different Environments. The member is a Service account for SSISDB server. It is currently used in a Step Template in Octopus: http://octopus.*****.ds/app#/Spaces-1/library/steptemplates/ActionTemplates-781?activeTab=step


# Top Level Variables
$ServerName = $OctopusParameters["st-SSASServerName"]
$DB = $OctopusParameters["st-Database"]
$MemberName = $OctopusParameters["st-MemberName"]
$RoleName = $OctopusParameters["st-RoleName"]

Import-Module SqlServer
$MyServer = New-Object Microsoft.AnalysisServices.Server
$MyServer.Connect($ServerName)
Add-RoleMember -MemberName $MemberName -Database $DB -RoleName $RoleName -Server $MyServer
Write-Host "The member:"$MemberName "was added successfully to the role" $RoleName 
