# Name: Extract Role members from SSAS Server for all databases to XML.ps1
# Created by: Sanket Keni
# Date created: 08/27/2019
# Scope: ******
# Description: This PS Script is used to extract Role members from SSAS Server for all databases to XML. This specifically designed to extract role information from existing 2008 Dev,Test and Prod SSAS Servers. These XML files will be used as inputs when configuring the Roles and Members for 2016 SSAS Databases.
# Notes: A separate folder will be created for each Database and each folder will have 3 XML config files. (each for Dev, Test and Prod). This script was designed for 1 server hosting mutiple Databases.



[Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
Import-Module SqlServer

########## High Level Inputs ##########
$SSASDevServer = 'Dev Server 1'
$SSASTestServer = 'Test Server 1'
$SSASProdServer = 'Prod Server 1'
$OutputDirectory = 'C:\Files\'
$DatabaseList = 'SSAS DB2', 'SSAS DB2', 'SSAS DB3', 'SSAS DB4', 'SSAS DB5', 'SSAS DB6', 'SSAS DB7', 'SSAS DB8', 'SSAS DB9', 'SSAS DB10'  #List of Databases to extract
#######################################


#Creating the object for SSAS Server
$ServerObjectSSAS  = @()
$NewItem = New-Object -TypeName psobject
$NewItem | Add-Member -MemberType NoteProperty -Name ServerNameSSAS -Value $SSASDevServer
$NewItem | Add-Member -MemberType NoteProperty -Name Environment -Value 'DEV'
$ServerObjectSSAS += $NewItem
$NewItem = New-Object -TypeName psobject
$NewItem | Add-Member -MemberType NoteProperty -Name ServerNameSSAS -Value $SSASTestServer
$NewItem | Add-Member -MemberType NoteProperty -Name Environment -Value 'TEST'
$ServerObjectSSAS += $NewItem
$NewItem = New-Object -TypeName psobject
$NewItem | Add-Member -MemberType NoteProperty -Name ServerNameSSAS -Value $SSASProdServer
$NewItem | Add-Member -MemberType NoteProperty -Name Environment -Value 'PROD'
$ServerObjectSSAS += $NewItem



#Loop Over all the SSAS Servers (Dev, Test. Prod)

$ServerObjectSSAS | ForEach-Object {

	# SSAS server name variable
	$SSASServerName = $_.ServerNameSSAS

	# Environment (DEV/TEST/PROD)
	$Environment = $_.Environment

	# Try to connect to the SSAS server
	Write-Host 'Connecting to' $SSASServerName 'Server'
	$SSASServer = New-Object Microsoft.AnalysisServices.Server
	$SSASServer.Connect($SSASServerName)

	# Object to store the Roles from current Server
	$RoleObjectFromServer = @()

		# Get the SSAS databases and loop thru each of them
		foreach ($DB in $SSASServer.Databases)
		{
			# Get the SSAS database
			$SSASDatabase = $SSASServer.Databases.Item($DB.name)

			# Get the roles available within the SSAS database and loop thru each of them
			foreach ($Role in $SSASDatabase.Roles)
			{
				# Get the members within the role and loop thru each one of them
				foreach ($UserName in $Role.Members)
				{
					# Create a new object that would store the database name, role name and member user name
					$ItemResult = New-Object System.Object
					$ItemResult | Add-Member -type NoteProperty -name DatabaseName -value $DB.Name
					$ItemResult | Add-Member -type NoteProperty -name RoleName -value $Role.Name
					$ItemResult | Add-Member -type NoteProperty -name UserName -value $UserName.Name

					# Put the item result and append it to the result object
					$RoleObjectFromServer +=$ItemResult
				}
			}
		}

		#$RoleObjectFromServer | Select 'po'+DatabaseName, RoleName, UserName where DatabaseName = 'SSAS Project Control' | Export-Csv -Path C:\Outputs\SSASRoles.csv -NoTypeInformation


		# Creating an XML file for each Database
		$DatabaseList | ForEach-Object {

				#Create a Database Folder
				$SSASTargetDirectory = $OutputDirectory + $_ + '\'
				if(!(Test-Path -Path $SSASTargetDirectory )){
					New-Item -ItemType directory -Path $SSASTargetDirectory *>$null
				}

				#Initializing XML file
				$FinalXML = '<?xml version="1.0" encoding="utf-8"?>	<configuration> <SecurityRoles>'

				$currDatabase = $_

				# Add Role information to XML string
				$RoleObjectFromServer | ForEach-Object {
					if($_.DatabaseName -contains $currDatabase) {
						$FinalXML = $FinalXML + '<Member role="' + $_.RoleName.replace("&","&amp;") + '" member="' + $_.UserName.replace("&","&amp;") + '"></Member>'
					}			
				}

				Write-Host 'Creating XML config file for' $Environment $currDatabase

				# Ending XML File
				$FinalXML = $FinalXML + ' </SecurityRoles> </configuration>'

				# Creating Full File Path
				$FilePath = $SSASTargetDirectory + 'ConfigRoles.' + $Environment + '.xml'
				
				# Creating the XML File
				$FinalXML | out-file $FilePath
		}

}
















