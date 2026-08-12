<#
.SYNOPSIS
    Reports a full inventory of Active Directory user accounts: identity, enabled
    state, OU placement, key timestamps, and group memberships.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 02 (Group and OU Administration).
    Run from WIN11-CLIENT01 via RSAT against DC01, per ADR-016.

    Read-only: makes no changes to Active Directory. Every user account in the
    domain is included regardless of Enabled state. Group memberships are resolved
    per account with Get-ADPrincipalGroupMembership and joined into a single "; "
    delimited field so each account is one CSV row. The primary group (Domain Users)
    is excluded from that field using the same PrimaryGroup-comparison pattern
    Remove-LabUser.ps1 (Lab 01) uses to distinguish removable memberships from the
    primary group, since every account shares the same primary group and including
    it in every row would add no differentiating signal. LastLogonDate is left
    blank when AD returns no value (a replicated attribute that only updates
    periodically, not on every logon) rather than substituted with a placeholder.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

Import-Module ActiveDirectory

Write-Host "Querying all user accounts in corp.home.arpa..." -ForegroundColor Cyan

$users = Get-ADUser -Filter * -Properties Enabled, DistinguishedName, whenCreated, PasswordLastSet, LastLogonDate, PrimaryGroup |
    Sort-Object SamAccountName

Write-Host "Found $($users.Count) user account(s). Resolving group memberships per account..." -ForegroundColor Cyan

$report = foreach ($user in $users) {
    $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName |
        Where-Object { $_.DistinguishedName -ne $user.PrimaryGroup } |
        Select-Object -ExpandProperty Name

    [PSCustomObject]@{
        Name              = $user.Name
        SamAccountName    = $user.SamAccountName
        Enabled           = $user.Enabled
        DistinguishedName = $user.DistinguishedName
        WhenCreated       = $user.whenCreated
        PasswordLastSet   = $user.PasswordLastSet
        LastLogonDate     = $user.LastLogonDate
        Groups            = $groups -join "; "
    }
}

$report | Format-Table -AutoSize

if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Report exported to '$ExportPath'." -ForegroundColor Green
}
