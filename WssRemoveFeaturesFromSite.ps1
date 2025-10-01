###########################################################################################################
##
## Name:	WssRemoveFeaturesFromSite
## Author:	Stefan Goﬂner
##
## Version Information
## 2.0.0    17.01.2022		Powershell version
##
###########################################################################################################
##
##  This source code is freeware and is provided on an "as is" basis without warranties of any kind, 
##  whether express or implied, including without limitation warranties that the code is free of defect, 
##  fit for a particular purpose or non-infringing.  The entire risk as to the quality and performance of 
##  the code is with the end user.
##
###########################################################################################################



param(
        [Parameter(Mandatory, HelpMessage="Please provide the Url to the specific site")]
	[String] $SiteUrl,
        [Parameter(Mandatory, HelpMessage="Please provide the Id (Guid) of the feature to be removed")]
	[Guid] $FeatureId,
        [Parameter(Mandatory, HelpMessage="Please provide the Scope of the feature")]
        [ValidateSet("Site","SiteCollection")]
	[String] $Scope,
        [Boolean] $Force
)


$Assem = (
    ìMicrosoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429cî
    )
$Source = @î
using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SharePoint;

namespace StefanG.Tools
{
    public class WssRemoveFeatureFromSite
    {
        static private String Version = "2.0.0";

        private enum Scope
        {
            notdefined,
            site,
            sitecollection,
        }

        public static void RemoveFeature(string SiteUrl, string ScopeStr, string FeatureId, bool bforce)
        {
            Console.WriteLine("WssRemoveFeatureFromSite V"+Version+" - Stefan Goﬂner (StefanG@Microsoft.com)\n");

            string url = SiteUrl;
            bool force = bforce;
            Guid featureid = Guid.Empty;
            Guid.TryParse(FeatureId, out featureid);
            Scope scope = Scope.notdefined;

            if (ScopeStr.ToLower() == "site")
                scope = Scope.site;
            if (ScopeStr.ToLower() == "sitecollection")
                scope = Scope.sitecollection;

            if (url == null)
            {
                Console.WriteLine("Error: Invalid URL to site");
                return;
            }

            if (featureid == Guid.Empty)
            {
                Console.WriteLine("Error: Invalid feature ID!");
                return;
            }

            if (scope == Scope.notdefined)
            {
                Console.WriteLine("Error: Scope not defined!");
                return;
            }

            SPSite site = null;
            SPWeb web = null;

            try
            {
                site = new SPSite(url);
                string siteurl = site.Url;
                if (scope == Scope.site)
                {
                    web = site.OpenWeb(new Uri(url).AbsolutePath);
                    siteurl = web.Url;
                }
            }
            catch
            {
                Console.WriteLine("Error: Url is not a valid URL for a site: " + url);
                return;
            }

            if (scope == Scope.site)
            {
                SPFeature feature = null;
                try
                {
                    feature = web.Features[featureid];
                    if (feature == null)
                    {
                        Console.WriteLine("Error: Feature with id '" + featureid + "' not found at Site with Url '" + url + "'");
                        return;
                    }
                }
                catch
                {
                    Console.WriteLine("Error: Feature with id '" + featureid + "' not found at Site with Url '" + url + "'");
                    return;
                }

                try
                {
                    if (force)
                        web.Features.Remove(featureid,true);
                    else
                        web.Features.Remove(featureid);
                    web.Update();
                }
                catch (Exception e)
                {
                    if (feature.Definition == null)
                    {
                        Console.WriteLine("Error removing feature with id '" + featureid + "' from Site with URL '" + url + "'");
                        Console.WriteLine("Feature Definition does not exist. You need to use the '-force' option to remove this feature");
                        return;
                    }
                    else
                    {
                        Console.WriteLine("Exception: " + e.GetType() + " - " + e.Message);
                        Console.WriteLine("Exception-Stacktrace: \n" + e.StackTrace);
                        if (e.InnerException != null)
                        {
                            Console.WriteLine("Inner-Exception: " + e.InnerException.GetType() + " - " + e.Message);
                            Console.WriteLine("Inner-Exception-Stacktrace: \n" + e.InnerException.StackTrace);
                        }
                        Console.WriteLine("\nError removing feature with id '" + featureid + "' from Site with URL '" + url + "'");
                        Console.WriteLine("Please retry with '-force' option");
                        return;
                    }
                }
                Console.WriteLine("Feature with id '" + featureid + "' successfully removed from Site with URL '" + url + "'");
            }

            if (scope == Scope.sitecollection)
            {
                SPFeature feature = null;
                try
                {
                    feature = site.Features[featureid];
                    if (feature == null)
                    {
                        Console.WriteLine("Error: Feature with id '" + featureid + "' not found at Site Collection with Url '" + url + "'");
                        return;
                    }
                }
                catch
                {
                    Console.WriteLine("Error: Feature with id '" + featureid + "' not found at Site Collection with Url '" + url + "'");
                    return;
                }

                try
                {
                    if (force)
                        site.Features.Remove(featureid,true);
                    else
                        site.Features.Remove(featureid);
                }
                catch (Exception e)
                {
                    if (feature.Definition == null)
                    {
                        Console.WriteLine("Error removing feature with id '" + featureid + "' from Site Collection with URL '" + url + "'");
                        Console.WriteLine("Feature Definition does not exist. You need to use the '-force' option to remove this feature");
                        return;
                    }
                    else
                    {
                        Console.WriteLine("Exception: " + e.GetType() + " - " + e.Message);
                        Console.WriteLine("Exception-Stacktrace: \n" + e.StackTrace);
                        if (e.InnerException != null)
                        {
                            Console.WriteLine("Inner-Exception: " + e.InnerException.GetType() + " - " + e.Message);
                            Console.WriteLine("Inner-Exception-Stacktrace: \n" + e.InnerException.StackTrace);
                        }
                        Console.WriteLine("\nError removing feature with id '" + featureid + "' from Site Collection with URL '" + url + "'");
                        Console.WriteLine("Please retry with '-force' option");
                        return;
                    }
                }
                Console.WriteLine("Feature with id '" + featureid + "' successfully removed from Site Collection with URL '" + url + "'");
            }

        }
    }
}
ì@

$currentDir = get-location

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 

[StefanG.Tools.WssRemoveFeatureFromSite]::RemoveFeature($SiteUrl, $Scope, $FeatureId, $Force)
