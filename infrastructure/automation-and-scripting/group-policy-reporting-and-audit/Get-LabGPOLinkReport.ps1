<#
.SYNOPSIS
    Reports, per organizational unit, which Group Policy Objects are linked
    or inherited, their precedence order, enabled/enforced state, and
    whether inheritance is blocked.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 04 (Group Policy
    Reporting and Audit). Run from WIN11-CLIENT01 via RSAT against DC01, per
    ADR-016.

    Read-only: makes no changes to Group Policy. Every OU in the domain is
    enumerated with Get-ADOrganizationalUnit -Filter *, the same approach
    Get-LabOUReport.ps1 (Lab 02) uses, sorted by Name for stable output. For
    each OU, Get-GPInheritance -Target <OU DN> is queried once, and the
    report is flattened to one row per GPO in that OU's effective,
    precedence-ordered InheritedGpoLinks list, the full set of GPOs that
    actually apply there (directly linked plus anything inherited from a
    parent, such as the domain-level Default Domain Policy), rather than
    only the OU's own direct GpoLinks. DirectlyLinked distinguishes a GPO
    linked at this specific OU from one only present because it is
    inherited from further up the tree, by checking whether the same
    DisplayName also appears in the OU's own GpoLinks collection.
    GpoInheritanceBlocked and each link's Enabled/Enforced/Order fields are
    reported as Get-GPInheritance returns them, unmodified.

    An OU with no GPOs in its effective InheritedGpoLinks list contributes
    no rows to the report rather than a placeholder row, since there is no
    link to report for it. In this environment, with Default Domain Policy
    linked at the domain root, that case would only occur if inheritance
    were disabled at the root itself.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

Import-Module ActiveDirectory
Import-Module GroupPolicy

Write-Host "Enumerating organizational units under corp.home.arpa..." -ForegroundColor Cyan

$ous = Get-ADOrganizationalUnit -Filter * | Sort-Object Name

Write-Host "Found $($ous.Count) OU(s). Querying Group Policy link and inheritance state per OU..." -ForegroundColor Cyan

$report = foreach ($ou in $ous) {
    $inheritance = Get-GPInheritance -Target $ou.DistinguishedName

    foreach ($link in $inheritance.InheritedGpoLinks) {
        $directlyLinked = [bool]($inheritance.GpoLinks | Where-Object { $_.DisplayName -eq $link.DisplayName })

        [PSCustomObject]@{
            OUName                = $ou.Name
            OUDistinguishedName   = $ou.DistinguishedName
            GpoDisplayName        = $link.DisplayName
            LinkOrder             = $link.Order
            DirectlyLinked        = $directlyLinked
            LinkEnabled           = $link.Enabled
            LinkEnforced          = $link.Enforced
            GpoInheritanceBlocked = $inheritance.GpoInheritanceBlocked
        }
    }
}

$report | Format-Table -AutoSize

if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Report exported to '$ExportPath'." -ForegroundColor Green
}
