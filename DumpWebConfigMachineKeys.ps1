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
    
   This script dumps the machine keys stored in all SharePoint web.config files of the current SharePoint farm in clear text.
   This is especially useful if the machine keys are stored in encrypted form.

   Be aware that these machine keys get overwritten in memory by values stored in the configuration database.
   The SharePoint machine key rotation job does not update the web.config files to avoid application domain restarts.

   Reference: tbd

   Version History:
    1.0 - initial version
  
#>


if ("StefanG.Tools.WebConfigMachineKeys" -as [type]) { } else { 

$Assem = (
    “System.Web” ,
    “System.Configuration”
    )
$Source = @”
using System;
using System.Configuration;
using System.IO;
using System.Web.Configuration;

namespace StefanG.Tools
{
    public class WebConfigMachineKeys
    {
        public static void Dump()
        {
            string rootPath = "C:\\inetpub\\wwwroot\\wss\\VirtualDirectories\\";

            string[] subdirectories = Directory.GetDirectories(rootPath, "*", SearchOption.TopDirectoryOnly);

            foreach (string subDir in subdirectories)
            {
                string physicalPath = Path.Combine(rootPath, subDir);

                try
                {
                    // Create a configuration file map for the physical directory
                    WebConfigurationFileMap configFileMap = new WebConfigurationFileMap();
                    configFileMap.VirtualDirectories.Add("/", new VirtualDirectoryMapping(physicalPath, true, "web.config"));

                    // Open the configuration using the file map
                    Configuration config = WebConfigurationManager.OpenMappedWebConfiguration(configFileMap, "/");

                    // Get the machineKey section
                    MachineKeySection machineKey = (MachineKeySection)config.GetSection("system.web/machineKey");

                    // Emit Validation and Decryption Key
                    if (machineKey != null)
                    {
                        Console.WriteLine(Path.GetFileName(subDir) + " - Validation Key: " + machineKey.ValidationKey);
                        Console.WriteLine(Path.GetFileName(subDir) + " - Decryption Key: " + machineKey.DecryptionKey);
                        Console.WriteLine("-----------------------------------------------------------------------------------------");
                    }
                    else
                    {
                        Console.WriteLine("<machineKey> section not found.");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Error reading configuration: " + ex.Message);
                }

            }

        }
    }
}
“@

    Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp 
}

[StefanG.Tools.WebConfigMachineKeys]::Dump()
