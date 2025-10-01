###########################################################################################################
##
##  Name:	WssAnalyzeFeatures
##  Author:	Stefan Goßner
##
##  Version Information
##  2.0.0    17.01.2022		Powershell version
##
###########################################################################################################
##
##  Syntax: 
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
        [Parameter(Mandatory, HelpMessage="Please pass the Url to the site collection to be analyzed")]
	[String] $SiteUrl
)


$Assem = (
    “Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c”
    )
$Source = @”

using System;
using System.IO;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Text;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Administration;

namespace StefanG.Tools
{
    public class WssAnalyzeFeatures
    {
        static private String Version = "2.0.0";

        static Stack<Guid> stack = new Stack<Guid>();
        static SPSite site = null;
        static StreamWriter wTxt;
        static StreamWriter wTxtDpl;
        static StreamReader rVerify;
        static int errorcount = 0;
        static bool SiteErrors = false;
        static string URL = null;
        static string verifyFile = null;
        static string currentDir = null;

        static SortedDictionary<string, SPFeature> dplFeatures = new SortedDictionary<string, SPFeature>();

        // internal method to check if a specific feature is valid or not
        static string CheckFeature(SPFeature feature)
        {
            string ret = null;

            if (!dplFeatures.ContainsKey(feature.DefinitionId.ToString().ToLower()))
                dplFeatures.Add(feature.DefinitionId.ToString().ToLower(), feature);

            if (feature.Definition == null)
            {
                ret = "- Feature Id=" + feature.DefinitionId + ": Error: Feature not installed!\r\n";
                errorcount += 1;
            }
            else
            {
                string featureFile = feature.Definition.RootDirectory + "\\feature.xml";
                if (!File.Exists(featureFile))
                {
                    ret = "- Feature Id=" + feature.Definition.Id + ": Error: Missing File \"" + featureFile + "\"\r\n";
                    errorcount += 1;
                }
            }
            return ret;
        }

        /// <summary>
        /// Check if the feature definitions for the features used in the site are installed and usable
        /// </summary>
        static void CheckFeaturesOnWeb()
        {
            while (stack.Count > 0)
            {
                using (SPWeb web = site.OpenWeb(stack.Pop()))
                {
                    Console.WriteLine("Checking Features on Site: " + web.Url);
                    string check = "";
                    foreach (SPFeature feature in web.Features)
                    {
                        check += CheckFeature(feature);
                    }
                    if (!string.IsNullOrEmpty(check))
                    {
                        if (!SiteErrors)
                            wTxt.WriteLine("Problems with Site Features: ");
                        wTxt.WriteLine("Site: " + web.Url);
                        wTxt.WriteLine(check);
                        SiteErrors = true;
                    }

                    foreach (SPWeb w in web.Webs)
                    {
                        stack.Push(w.ID);
                        w.Dispose();
                    }
                }
            }
        }

        /// <summary>
        /// Check if the feature definition files for the installed features are available on the file system.
        /// </summary>
        static void CheckInstalledFeatures()
        {
            Console.WriteLine("Checking installed features...");

            bool allOk = true;
            SPFarm farm = SPFarm.Local;
            foreach (SPFeatureDefinition fd in farm.FeatureDefinitions)
            {
                string featureFile = fd.RootDirectory + "\\feature.xml";
                if (!File.Exists(featureFile))
                {
                    if (allOk)
                    {
                        wTxt.WriteLine("Problems with installed features:");
                    }
                    wTxt.WriteLine("- Feature Id=" + fd.Id + ": Error: Missing File \"" + featureFile + "\"");
                    errorcount += 1;
                    allOk = false;
                }
            }
            if (allOk)
            {
                wTxt.WriteLine("No Problem found for the installed features.");
            }
        }

        /// <summary>
        /// Check if the feature definitions for the features used in the site collection are installed and usable
        /// </summary>
        static void CheckSiteCollectionFeatures()
        {
            Console.WriteLine("Checking Features on Site Collection: " + site.Url);
            string check = null;
            foreach (SPFeature feature in site.Features)
            {
                check += CheckFeature(feature);
            }
            if (!string.IsNullOrEmpty(check))
            {
                wTxt.WriteLine("Problems with Site Collection Features: " + site.Url);
                wTxt.Write(check);
            }
            else
            {
                wTxt.WriteLine("No Problem found for Site Collection features.");
            }
        }

        /// <summary>
        /// Verify if the target server has all the required features based on the info in the provided checklist file
        /// </summary>
        static void VerifyFeatures()
        {
            FileStream fsVerify = null;
            if (verifyFile != null)
            {
                try
                {
                    fsVerify = new FileStream(verifyFile, FileMode.Open, FileAccess.Read);
                }
                catch
                {
                    Console.WriteLine("ERROR: Cannot read from file \"" + verifyFile + "\".\r\n");
                }
                rVerify = new StreamReader(fsVerify);
                StringDictionary dict = new StringDictionary();
                SPFarm farm = SPFarm.Local;
                while (!rVerify.EndOfStream)
                {
                    string zeile = rVerify.ReadLine();
                    string[] parameter = zeile.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);

                    SPFeatureDefinition fd = null;
                    try
                    {
                        fd = farm.FeatureDefinitions[new Guid(parameter[1])];
                    }
                    catch
                    {
                    }
                    finally
                    {
                        if (fd == null)
                            wTxt.WriteLine("Missing Feature: " + parameter[1] + ", " + parameter[2]);
                    }

                }
            }
        }

        /// <summary>
        /// Write the checklist necessary to verify the features on the target server for content deployment
        /// </summary>
        static void WriteDeploymentChecklist()
        {
            string filename2 = Path.Combine(currentDir, "ContentDeploymentFeatures.txt");
            FileStream fsTxtDpl = null;
            try
            {
                fsTxtDpl = new FileStream(filename2, FileMode.Create, FileAccess.Write);
            }
            catch
            {
                System.Console.WriteLine("ERROR: Cannot write to file \"" + filename2 + "\".\r\n");
                return;
            }
            System.Console.WriteLine("Required Features for Content Deployment will be written to \"" + filename2 + "\"\r\n");
            wTxtDpl = new StreamWriter(fsTxtDpl);


            foreach (string k in dplFeatures.Keys)
            {
                wTxtDpl.WriteLine("Feature|" + k + "|" + ((dplFeatures[k].Definition == null) ? "Error: Not Installed" : dplFeatures[k].Definition.DisplayName));
            }

            wTxtDpl.Close();
        }

        public static void AnalyzeFeatures(string workingDir, string SiteUrl, string ChecklistFile=null)
        {
            URL = SiteUrl;
            verifyFile = ChecklistFile;
            currentDir = workingDir;

Console.WriteLine("CurrentDir: "+currentDir); 

            string filename = Path.Combine(currentDir, "FeatureProblems.txt");
            FileStream fsTxt = null;
            try
            {
                fsTxt = new FileStream(filename, FileMode.Create, FileAccess.Write);
            }
            catch
            {
                System.Console.WriteLine("ERROR: Cannot write to file \"" + filename + "\".\r\n");
                return;
            }
            System.Console.WriteLine("Feature Error information will be written to \"" + filename + "\"\r\n");
            System.Console.WriteLine("Feature Error information will be written to \"" + fsTxt.Name + "\"\r\n");
            System.Console.WriteLine("Directory.GetCurrentDirectory() \"" + Directory.GetCurrentDirectory() + "\"\r\n");

            wTxt = new StreamWriter(fsTxt);

            wTxt.WriteLine("WssAnalyzeFeatures V" + Version + "\r\n");
            CheckInstalledFeatures();
            VerifyFeatures();

            wTxt.WriteLine();

            if (URL != null)
            {
                using (site = new SPSite(URL))
                {
                    CheckSiteCollectionFeatures();

                    wTxt.WriteLine();

                    int PreErrorCount = errorcount;
                    using (SPWeb web = site.RootWeb)
                    {
                        stack.Push(web.ID);
                        web.Dispose();
                        CheckFeaturesOnWeb();
                    }
Console.WriteLine("errorcount: " + errorcount + ", PreErrorCount: " + PreErrorCount);
                    if (errorcount == PreErrorCount)
                    {
                        wTxt.WriteLine("No Problem found for Site features.");
                    }
                }

                WriteDeploymentChecklist();
            }

            wTxt.Close();

            if (errorcount > 0)
                Console.WriteLine("\r\n" + errorcount + " Errors found. Please check logfile for details.");
            else
                Console.WriteLine("\r\n" + errorcount + " Errors found.");
        }
    }
}
“@

$currentDir = get-location

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 

[StefanG.Tools.WssAnalyzeFeatures]::AnalyzeFeatures($currentDir, $SiteUrl)
