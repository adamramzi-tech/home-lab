<#
.SYNOPSIS
    Provisions a new Active Directory user account in the corp.home.arpa domain,
    with optional Linux access, and validates the result.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 01 (User Lifecycle Automation).
    Run from WIN11-CLIENT01 via RSAT against DC01, per ADR-016.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$SamAccountName,

    [Parameter(Mandatory = $false)]
    [string]$TargetOU = "OU=User Accounts,DC=corp,DC=home,DC=arpa",

    [Parameter(Mandatory = $false)]
    [ValidateSet("IT-Admins", "Domain-Users-Standard")]
    [string]$RoleGroup = "Domain-Users-Standard",

    [Parameter(Mandatory = $false)]
    [switch]$LinuxAccess,

    [Parameter(Mandatory = $true)]
    [System.Security.SecureString]$InitialPassword
)

Import-Module ActiveDirectory

# Abort if an account with this SamAccountName already exists
Write-Host "Checking whether '$SamAccountName' already exists in Active Directory..." -ForegroundColor Cyan

try {
    $existing = Get-ADUser -Identity $SamAccountName -ErrorAction Stop
    Write-Host "ABORT: an account with SamAccountName '$SamAccountName' already exists ($($existing.DistinguishedName))." -ForegroundColor Red
    return
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "OK: no existing account named '$SamAccountName'. Safe to proceed." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: could not query Active Directory ($($_.Exception.Message))." -ForegroundColor Red
    return
}

# Derive display name and UPN from the supplied parameters
$displayName = "$FirstName $LastName"
$userPrincipalName = "$SamAccountName@corp.home.arpa"

Write-Host "Creating account '$SamAccountName' in $TargetOU..." -ForegroundColor Cyan

New-ADUser `
    -Name $displayName `
    -SamAccountName $SamAccountName `
    -UserPrincipalName $userPrincipalName `
    -GivenName $FirstName `
    -Surname $LastName `
    -DisplayName $displayName `
    -Path $TargetOU `
    -AccountPassword $InitialPassword `
    -ChangePasswordAtLogon $true `
    -Enabled $true

# Assign the role group
Write-Host "Adding '$SamAccountName' to role group '$RoleGroup'..." -ForegroundColor Cyan
Add-ADGroupMember -Identity $RoleGroup -Members $SamAccountName

# Grant Linux access only when requested
if ($LinuxAccess) {
    Write-Host "Adding '$SamAccountName' to 'Linux-Admins' (Linux access requested)..." -ForegroundColor Cyan
    Add-ADGroupMember -Identity "Linux-Admins" -Members $SamAccountName
}
else {
    Write-Host "Linux access not requested; skipping Linux-Admins membership." -ForegroundColor DarkGray
}

# Validate the result by querying AD back, rather than trusting the cmdlets above
Write-Host "Validating provisioned account against Active Directory..." -ForegroundColor Cyan

$created = Get-ADUser -Identity $SamAccountName -Properties Enabled, DistinguishedName
$groups  = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name

# Account exists and is enabled
if ($created -and $created.Enabled) {
    Write-Host "PASS: account exists and is enabled." -ForegroundColor Green
}
else {
    Write-Host "FAIL: account missing or not enabled." -ForegroundColor Red
}

# Account resides in the requested OU
if ($created.DistinguishedName -like "*$TargetOU") {
    Write-Host "PASS: account is in the target OU ($TargetOU)." -ForegroundColor Green
}
else {
    Write-Host "FAIL: account is not in the expected OU. Found: $($created.DistinguishedName)" -ForegroundColor Red
}

# Role group membership
if ($groups -contains $RoleGroup) {
    Write-Host "PASS: member of role group '$RoleGroup'." -ForegroundColor Green
}
else {
    Write-Host "FAIL: not a member of role group '$RoleGroup'." -ForegroundColor Red
}

# Linux-Admins membership matches what was requested
if ($LinuxAccess) {
    if ($groups -contains "Linux-Admins") {
        Write-Host "PASS: member of Linux-Admins (Linux access requested)." -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: Linux access requested but not a member of Linux-Admins." -ForegroundColor Red
    }
}
else {
    if ($groups -notcontains "Linux-Admins") {
        Write-Host "PASS: not a member of Linux-Admins (Linux access not requested)." -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: not requested, but unexpectedly a member of Linux-Admins." -ForegroundColor Red
    }
}