<#
.SYNOPSIS
    Reports a full inventory of Group Policy Objects in the domain: identity,
    configuration-side enablement, and creation/modification timestamps.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 04 (Group Policy
    Reporting and Audit). Run from WIN11-CLIENT01 via RSAT against DC01, per
    ADR-016.

    Read-only: makes no changes to Group Policy. Every GPO in the domain is
    enumerated with Get-GPO -All, which returns both the two built-in
    policies (Default Domain Policy, Default Domain Controllers Policy) and
    the three purpose-built GPOs from enterprise infrastructure Lab 05
    (Workstation-Security-Baseline, Standard-User-Environment,
    IT-Admin-Environment). Results are sorted by DisplayName for stable
    output, the same ordering approach Get-LabOUReport.ps1 and
    Get-LabAccountInventory.ps1 (Lab 02) used for their own reports.
    GpoStatus reports which side of each GPO (Computer Configuration, User
    Configuration, both, or neither) is currently enabled.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

Import-Module GroupPolicy

Write-Host "Enumerating Group Policy Objects in corp.home.arpa..." -ForegroundColor Cyan

$gpos = Get-GPO -All | Sort-Object DisplayName

Write-Host "Found $($gpos.Count) GPO(s)." -ForegroundColor Cyan

$report = foreach ($gpo in $gpos) {
    [PSCustomObject]@{
        DisplayName      = $gpo.DisplayName
        Id               = $gpo.Id
        GpoStatus        = $gpo.GpoStatus
        CreationTime     = $gpo.CreationTime
        ModificationTime = $gpo.ModificationTime
    }
}

$report | Format-Table -AutoSize

if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Report exported to '$ExportPath'." -ForegroundColor Green
}
