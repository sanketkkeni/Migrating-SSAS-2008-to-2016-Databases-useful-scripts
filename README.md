# Migrating-SSAS-2008-to-2016-Databases-useful-scripts
Some useful scripts I had created while working on migrating SSAS Databases from 2008 to 2016

List of Scripts::

installMSMDPUMP.ps1: This PS Script is used to Configure HTTP Access to Analysis Services on IIS. It is part of setup process when installing an SSAS Instance on a server. This is because SAP Users use HTTP to access SSAS Databases.

update-roles.ps1: This PS Script is used to apply roles and member information on the SSAS Database from XML Config files. It is supposed to be used as a Step Template in Octopus

SSASAddMembersInSecurityRoles.Powershell.ps1: This PS Script is used to add a member to Roles on SSAS Database. This is required as the members will be different in different Environments. The member is a Service account for SSISDB server. It is currently used in a Step Template in Octopus

Extract Role members from SSAS Server for all databases to XML.ps1: This PS Script is used to extract Role members from SSAS Server for all databases to XML. This specifically designed to extract role information from existing 2008 Dev,Test and Prod SSAS Servers. These XML files will be used as inputs when configuring the Roles and Members for 2016 SSAS Databases. Notes: A separate folder will be created for each Database and each folder will have 3 XML config files. (each for Dev, Test and Prod). This script was designed for 1 server hosting mutiple Databases.

Apply RoleMembers to SSAS Database using XML config file - Local Version.ps1: This PS Script is used to apply roles and member information on the SSAS Database from XML Config files. It is supposed to be run locally. 

Apply RoleMembers to SSAS Database using XML config file - Octopus Version.ps1: This PS Script is used to apply roles and member information on the SSAS Database from XML Config files. This script is part of an Octopus Step Template used while deploying SSAS Databases.
