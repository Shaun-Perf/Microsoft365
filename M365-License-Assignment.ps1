<#
   ###########################################################
####                                                   ####
####       🚀 SCRIPT BY: THATLAZYADMIN 🚀              ####
####                                                   ####
#####################################################################################################################

🎵 Script Composer: Shaun "ThatLazyAdmin" Hardneck 🎵

📞 Reach out and touch base! 📞
📧 Email: shaun@thatlazyadmin.com

🌐 Proudly brought to you by:
ThatLazyAdmin - "Making Admins Less Busy, More Lazy!" 
Check us out: www.thatlazyadmin.com

📜 Script's Tale 📜
This magical script sprinkles licenses over Microsoft 365 users based on their domain.
Last Updated on a sunny day of: 28/09/2023

⚠️ BE CAUTIOUS, WIZARD! ⚠️
Always test your spells (scripts) in a controlled environment before unleashing them onto the world!
Remember, with great power(Shell) comes great responsibility!
The composer and associated magical entities disclaim responsibility for any unintended dragons, I mean, outcomes.
#####################################################################################################################
#>

# Variables
$StaffDomain = "Domain.com"
$StudentsDomain = "User.com"
$ErrorActionPreference = "Stop"
$DebugFile = "C:\softlib\Error\Error.txt"
$dateTimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$SuccessFile = "C:\softlib\Error\Success_$dateTimeStamp.txt"

$StaffA2License = "5b631642-bd26-49fe-bd20-1daaa972ef80"
$StudentA2License = "studentsprestonac:STANDARDWOFFPACK_STUDENT"
$StaffProLicense = "f30db892-07e9-47e9-837c-80727f46fd3d"
$StudentProLicense = "studentsprestonac:M365EDU_A3_STUUSEBNFT"
$tenantId = "Tenant ID"
$scopes = "User.Read.All", "User.ReadWrite.All", "Directory.Read.All"

# Define Client ID and Client Secret for app authentication
$clientId = "CLient ID"
$clientSecret = "Client Secret"

# Authenticate to Microsoft Graph using Client ID and Client Secret
$tokenRequest = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $clientId
    Client_Secret = $clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $tokenRequest
$accessToken = $tokenResponse.access_token

# Connect to Graph with the acquired token
Connect-MgGraph -AccessToken $accessToken

# Get all Skus and their SkuPartNumbers
$allSkus = Get-MgSubscribedSku | Select-Object SkuId, SkuPartNumber

# Get all users first
$allUsers = Get-MgUser -Top 999

# Filter users with a 'mail' property in PowerShell (instead of using Graph's filter)
$users = $allUsers | Where-Object { $_.mail } | Select-Object id, mail, userPrincipalName

# Testing Limitation logic to be used for testing
$userLimit = 12
$counter = 0

# Define path for UsersAlreadyLicensed log
$UsersAlreadyLicensedFile = "C:\softlib\Error\UsersAlreadyLicensed_$dateTimeStamp.txt"

foreach ($user in $users) {
    # Testing logic: break the loop if we've processed the limit
    if ($counter -ge $userLimit) {
        break
    }
    $counter++

    # Check domain and assign the correct license accordingly
    if ($user.mail -like "*$StaffDomain") {
        $desiredLicenseId = $StaffA2License
    } elseif ($user.mail -like "*$StudentsDomain") {
        $desiredLicenseId = $StudentA2License
    } else {
        Add-Content -Path $DebugFile -Value "User $($user.mail) does not have a valid domain."
        continue
    }

    $skuPartNumber = ($allSkus | Where-Object { $_.SkuId -eq $desiredLicenseId }).SkuPartNumber

    # Fetch licenses for the user
    $userLicenses = Get-MgUserLicenseDetail -UserId $user.id | Select-Object -ExpandProperty SkuId

    if ($userLicenses -contains $desiredLicenseId) {
        Add-Content -Path $UsersAlreadyLicensedFile -Value "User $($user.mail) already licensed with $skuPartNumber."
        continue
    } else {
        try {
            # Assign the license
            $licenseToAssign = @{
                DisabledPlans = @()
                SkuId         = $desiredLicenseId
            }
            Set-MgUserLicense -UserId $user.id -AddLicenses @($licenseToAssign) -RemoveLicenses @()

            # Verify that the license has been successfully assigned
            $updatedLicenses = Get-MgUserLicenseDetail -UserId $user.id | Select-Object -ExpandProperty SkuId
            if ($updatedLicenses -contains $desiredLicenseId) {
                Add-Content -Path $SuccessFile -Value "Successfully applied $skuPartNumber to $($user.mail)."
            } else {
                Add-Content -Path $DebugFile -Value "Failed to verify license assignment for $($user.mail)."
            }
        } catch {
            Add-Content -Path $DebugFile -Value "Failed to assign license to $($user.mail). Error: $_"
        }
    }
}

Disconnect-MgGraph