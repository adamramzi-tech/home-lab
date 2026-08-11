<#
.SYNOPSIS
    Offboards an Active Directory user account: disables it, strips removable
    security-group memberships, and validates the result.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 01 (User Lifecycle Automation).
    Run from WIN11-CLIENT01 via RSAT against DC01, per ADR-016.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SamAccountName
)

Import-Module ActiveDirectory

# Abort if the account does not exist
Write-Host "Checking whether '$SamAccountName' exists in Active Directory..." -ForegroundColor Cyan

try {
    $user = Get-ADUser -Identity $SamAccountName -Properties Enabled, PrimaryGroup -ErrorAction Stop
    Write-Host "OK: found '$SamAccountName' ($($user.DistinguishedName))." -ForegroundColor Green
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "ABORT: no account named '$SamAccountName' exists." -ForegroundColor Red
    return
}
catch {
    Write-Host "ERROR: could not query Active Directory ($($_.Exception.Message))." -ForegroundColor Red
    return
}

# Disable the account first; this is the immediate security action
Write-Host "Disabling '$SamAccountName'..." -ForegroundColor Cyan
Disable-ADAccount -Identity $SamAccountName

# Strip removable security-group memberships, preserving the primary group
Write-Host "Removing removable group memberships from '$SamAccountName'..." -ForegroundColor Cyan

$groups = Get-ADPrincipalGroupMembership -Identity $SamAccountName |
    Where-Object { $_.DistinguishedName -ne $user.PrimaryGroup }

foreach ($group in $groups) {
    Write-Host "Removing '$SamAccountName' from '$($group.Name)'..." -ForegroundColor Cyan
    Remove-ADPrincipalGroupMembership -Identity $SamAccountName -MemberOf $group -Confirm:$false
}

# Validate the result by querying AD back, rather than trusting the cmdlets above
Write-Host "Validating offboarded account against Active Directory..." -ForegroundColor Cyan

$final = Get-ADUser -Identity $SamAccountName -Properties Enabled, PrimaryGroup
$remainingGroups = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty Name

# Account is disabled
if (-not $final.Enabled) {
    Write-Host "PASS: account is disabled." -ForegroundColor Green
}
else {
    Write-Host "FAIL: account is still enabled." -ForegroundColor Red
}

# Removable groups are gone
if ($groups.Count -eq 0) {
    Write-Host "PASS: no removable group memberships were present." -ForegroundColor Green
}
else {
    $stillRemoved = $groups | Where-Object { $remainingGroups -notcontains $_.Name }
    if ($stillRemoved.Count -eq $groups.Count) {
        Write-Host "PASS: all removable group memberships were removed." -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: some group memberships were not removed." -ForegroundColor Red
    }
}

# Primary group and account object are preserved
if ($final.PrimaryGroup -eq $user.PrimaryGroup) {
    Write-Host "PASS: primary group preserved; account object retained." -ForegroundColor Green
}
else {
    Write-Host "FAIL: primary group changed unexpectedly." -ForegroundColor Red
}