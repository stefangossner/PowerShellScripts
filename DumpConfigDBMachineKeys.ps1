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


  SUMMARY: 
    
   This script dumps the  machine keys for the current SharePoint farm as they are stored in the Configuration Database.
   This is useful if there are view state errors between different servers in the farm and can be used with troubleshooting 
   to identify replication problems between the configuration database and the configuration cache on the different SharePoint 
   servers.

   Reference: tbd

   Version History:
    1.0 - initial version
  
#>


if ("StefanG.Tools.ConfigDBMachineKeys" -as [type]) { } else { 

$Assem = (
    “Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c”
    )
$Source = @”
using Microsoft.SharePoint.Administration;
using System;

namespace StefanG.Tools
{
    public class ConfigDBMachineKeys
    {
        internal const string CredentialName = "MachineKeyConfiguration_";

        public static void Dump()
        {
            SPFarm farm = SPFarm.Local;
            SPWebServiceCollection webServices = new SPWebServiceCollection(farm);
            foreach (SPWebService webService in webServices)
            {
                foreach (SPWebApplication webapp in webService.WebApplications)
                {
                    // for simplicity we identify the web application name
                    string webAppName = webapp.Name ?? webapp.GetResponseUri(SPUrlZone.Default).Port.ToString();
                    if (webapp is SPAdministrationWebApplication)
                        webAppName = "Central Administration Webapplication";

                    try
                    {
                        // name of the object in the configuration database holding the machine keys for the given web application
                        string name = CredentialName + webapp.Id.ToString();

                        // retrieving the machine keys from config db (or more exactly the configuration cache of the local machine
                        SPSecureDBCredential cred = farm.GetObject(name, farm.Id, typeof(SPSecureDBCredential)) as SPSecureDBCredential;

                        // check for credentials
                        if (cred == null)
                        {
                            Console.WriteLine("No machine keys found for web application in config cache" + webAppName);
                            continue;
                        }

                        // validation and decryption key are stored in a single string separated by "|". Splitting.
                        string bothKeys = cred.Password;
                        string[] keys = bothKeys.Split('|');
                        string validationKey = keys[0];
                        string decryptionsKey = keys[1];

                        Console.WriteLine(webAppName);
                        Console.WriteLine(" - Validation Key: " + validationKey);
                        Console.WriteLine(" - Decryption Key: " + decryptionsKey);
                        Console.WriteLine("------------------------------------------------------------------------------------");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine("Error reading configuration for web application "+webAppName+": " + ex.Message);
                    }

                }
            }

        }
    }
}
“@

    Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
}

[StefanG.Tools.ConfigDBMachineKeys]::Dump()
