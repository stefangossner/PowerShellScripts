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


