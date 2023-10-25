# Variables
$tenantId = "1ef7750f-783b-430a-bcc2-75a799247c48"
$ErrorActionPreference = "Stop"
$dateTimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$UsersWithNoLicenseFile = "C:\Softlib\Error\NoLicense\UsersWithNoLicense_$dateTimeStamp.txt"

# Define Client ID and Client Secret for app authentication
$clientId = "ff716bcc-d776-400b-8259-b614a8cbeb1f"
$clientSecret = "-ul8Q~bWld~O0zw3V~tffNMr6FLD3LNw0qrFya6T"

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

# Fetch all member-type users 
$allUsers = Get-MgUser -Filter "assignedLicenses/`$count eq 0 and userType eq 'Member'" -ConsistencyLevel eventual -CountVariable unlicensedUserCount -All

# Filter the unlicensed users from the entire list
$unlicensedUsers = $allUsers | Where-Object { $_.AssignedLicenses.Count -eq 0 }

# Log the unlicensed users to a file
Add-Content -Path $UsersWithNoLicenseFile -Value "DisplayName,UserPrincipalName,LicenseStatus"
$unlicensedUsers | ForEach-Object {
    Add-Content -Path $UsersWithNoLicenseFile -Value "$($_.DisplayName),$($_.UserPrincipalName),License Not Found"
}

$unlicensedUserCount = ($unlicensedUsers | Measure-Object).Count
Write-Host "Found $unlicensedUserCount unlicensed users (excluding guests)."

# Disconnect from Graph
Disconnect-MgGraph

