<#
 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
 THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
 We grant you a nonexclusive, royalty-free right to use and modify the sample code and to reproduce and distribute the object 
 code form of the Sample Code, provided that you agree: 
    (i)   to not use our name, logo, or trademarks to market your software product in which the sample code is embedded; 
    (ii)  to include a valid copyright notice on your software product in which the sample code is embedded; and 
    (iii) to indemnify, hold harmless, and defend us and our suppliers from and against any claims or lawsuits, including 
          attorneys' fees, that arise or result from the use or distribution of the sample code.
 Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within 
              the Premier Customer Services Description.

#>

Add-PSSnapin Microsoft.Sharepoint.Powershell

$web = get-spweb http://jamondi-sp19:2000
$list = $web.Lists["Dokumente"];
$listItem = $list.Items[0];

$exportObject = new-object Microsoft.SharePoint.Deployment.SPExportObject
$exportObject.Id = $listItem.UniqueId
$exportObject.Type = [Microsoft.SharePoint.Deployment.SPDeploymentObjectType]::ListItem

$exportSettings = new-object Microsoft.SharePoint.Deployment.SPExportSettings
$exportSettings.ExportObjects.Add($exportObject)
$exportSettings.FileLocation = "c:\export"
$exportSettings.FileCompression = $false
$exportSettings.IncludeSecurity = [Microsoft.SharePoint.Deployment.SPIncludeSecurity]::All
$exportSettings.IncludeVersions = [Microsoft.SharePoint.Deployment.SPIncludeVersions]::All
#$exportSettings.BaseFileName = $listItem.Name
$exportSettings.SiteUrl = $web.Url

$export = new-object Microsoft.SharePoint.Deployment.SPExport $exportSettings
$export.Run()

# cleanup
$web.Dispose
$site.Dispose


