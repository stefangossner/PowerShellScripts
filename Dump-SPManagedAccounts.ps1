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
    
   This script dumps all username and passwords for SPManagedAccounts configured on the current SharePoint farm

   Reference: tbd

   Version History:
    1.0 - initial version
  
#>


# SharePoint PSSnapin laden (SP2016/2019)
#Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

# --------------------------------------------------
# Helper functions
# --------------------------------------------------

# BindingFlags for accessing private/internal instance fields of an object
function Get-BindingFlags {
    return [System.Reflection.BindingFlags]::CreateInstance `
        -bor [System.Reflection.BindingFlags]::GetField `
        -bor [System.Reflection.BindingFlags]::Instance `
        -bor [System.Reflection.BindingFlags]::NonPublic
}

# Read a private/internal field of an object via Reflection
function Get-NonPublicFieldValue {
    param(
        [object] $Object,
        [string] $FieldName
    )
    $flags = Get-BindingFlags
    return $Object.GetType().GetField($FieldName, $flags).GetValue($Object)
}

# SecureString to plain text (via marshalling and, zero out immediately after)
function ConvertTo-PlainText {
    param([System.Security.SecureString] $SecureString)

    $ptr = [System.IntPtr]::Zero

    try {
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecureString)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    }
    finally {
        # Securely zero and release unmanaged memory
        [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr)
    }
}

# ------------------------------------------------------
# List all Managed Accounts and extract their passwords
# ------------------------------------------------------

Get-SPManagedAccount | Select-Object UserName, @{
    Name       = "Password"
    Expression = {
        # 1) Retrieve private field m_Password (SPEncryptedString)
        $spEncryptedString = Get-NonPublicFieldValue -Object $_ -FieldName "m_Password"

        # 2) Access public property SecureStringValue (System.Security.SecureString)
        $secureString = $spEncryptedString.SecureStringValue

        # 3) Convert SecureString to plain text
        ConvertTo-PlainText -SecureString $secureString
    }
}
