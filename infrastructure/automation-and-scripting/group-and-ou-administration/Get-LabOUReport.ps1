<#
.SYNOPSIS
    Reports the current Active Directory OU structure with a user and computer
    object count per OU.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 02 (Group and OU Administration).
    Run from WIN11-CLIENT01 via RSAT against DC01, per ADR-016.

    Read-only: makes no changes to Active Directory. Counts are taken with
    -SearchScope OneLevel rather than the cmdlet default of Subtree, so each OU's
    row reflects only objects directly inside it, not objects in any OU nested
    beneath it. The current OU structure is flat, so this makes no difference
    today, but keeps the report accurate if OUs are ever nested later.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

Import-Module ActiveDirectory

Write-Host "Enumerating organizational units under corp.home.arpa..." -ForegroundColor Cyan

$ous = Get-ADOrganizationalUnit -Filter * | Sort-Object Name

Write-Host "Found $($ous.Count) OU(s). Counting user and computer objects per OU (SearchScope OneLevel)..." -ForegroundColor Cyan

$report = foreach ($ou in $ous) {
    $userCount = @(Get-ADUser -SearchBase $ou.DistinguishedName -SearchScope OneLevel -Filter *).Count
    $computerCount = @(Get-ADComputer -SearchBase $ou.DistinguishedName -SearchScope OneLevel -Filter *).Count

    [PSCustomObject]@{
        Name              = $ou.Name
        DistinguishedName = $ou.DistinguishedName
        UserCount         = $userCount
        ComputerCount     = $computerCount
    }
}

$report | Format-Table -AutoSize

if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Report exported to '$ExportPath'." -ForegroundColor Green
}
