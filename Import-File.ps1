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
