$Assem = (
    “Microsoft.SharePoint, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c”
    )
$Source = @”
using Microsoft.SharePoint;
using Microsoft.SharePoint.Deployment;
using System;

namespace StefanG.Tools
{
    public class ImportDocument
    {
        private static string _destSiteUrl;
        private static string _destLibrary;

        public static void DoImport(string ExportLocation, string DestSiteUrl, string DestLibrary)
        {
            _destSiteUrl = DestSiteUrl;
            _destLibrary = DestLibrary;

            SPImportSettings importSettings = new SPImportSettings();
            importSettings.SiteUrl = DestSiteUrl;
            importSettings.FileLocation = ExportLocation;
            importSettings.FileCompression = false;
            importSettings.RetainObjectIdentity = false;

            SPImport import = new SPImport(importSettings);

            EventHandler<SPDeploymentEventArgs> startedEventHandler = new EventHandler<SPDeploymentEventArgs>(OnStarted);
            import.Started += startedEventHandler;

            import.Run();
        } 

        static void OnStarted(object sender, SPDeploymentEventArgs args)
        {
            SPSite site = new SPSite(_destSiteUrl);
            SPWeb web = site.OpenWeb();
            SPList list = web.Lists[_destLibrary];

            SPImportObjectCollection rootObjects = args.RootObjects;
            foreach (SPImportObject io in rootObjects)
            {
                io.TargetParentUrl = list.RootFolder.ServerRelativeUrl;
            }

            web.Dispose();
            site.Dispose(); 
        }
    }
}
“@

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 

[StefanG.Tools.ImportDocument]::DoImport("c:\export", "http://jamondi-sp19:2000", "Dokumente2")
