Add-PSSnapin microsoft.sharepoint.powershell

$WebAppUrl = "http://contoso.com"

$WebApp = get-spwebapplication $WebAppUrl

$ContentDBs = $WebApp.ContentDatabases

$timerJobDef = Get-SPTimerJob | where {$_.Title -like "content organizer*" -and $_.WebApplication.Url -eq $WebApp.Url}

foreach ($db in $ContentDBs)
{
    write-host $db.Name, $db.Id

    $constructor = [Microsoft.SharePoint.Administration.SPJobState].GetConstructors([Reflection.BindingFlags] "NonPublic,Instance")
    
    $jobState = $constructor.Invoke([Object[]] @($timerJobDef.Id, $db.Id))

    $timerJobDef.Execute($db, $jobState)
}

