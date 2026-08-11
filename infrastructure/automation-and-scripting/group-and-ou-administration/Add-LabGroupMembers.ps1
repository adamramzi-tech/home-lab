<#
.SYNOPSIS
    Adds existing Active Directory accounts to one or more security groups in bulk,
    driven by a CSV input file, and validates the result.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 02 (Group and OU Administration).
    Run from WIN11-CLIENT01 via RSAT against DC01, per ADR-016.

    CSV input must contain 'GroupName' and 'SamAccountName' columns, one row per
    account-to-group assignment. Rows are grouped by GroupName so each group is
    written to once. Each requested member is validated individually with Get-ADUser
    before Add-ADGroupMember is called, since Add-ADGroupMember validates its entire
    -Members array atomically: a single invalid name blocks every valid member in the
    same call (confirmed against a disposable test group, Test-BulkAdd-Verify, during
    Lab 02 Step Two).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

Import-Module ActiveDirectory

# Import the CSV and confirm it has the expected columns before processing any rows
Write-Host "Importing CSV from '$CsvPath'..." -ForegroundColor Cyan

$rows = Import-Csv -Path $CsvPath

if (-not ($rows | Get-Member -Name "GroupName") -or -not ($rows | Get-Member -Name "SamAccountName")) {
    Write-Host "ABORT: CSV must contain 'GroupName' and 'SamAccountName' columns." -ForegroundColor Red
    return
}

Write-Host "OK: CSV imported with $($rows.Count) row(s)." -ForegroundColor Green

# Group rows by target group so each group is written to once, not once per member
$groupedRows = $rows | Group-Object -Property GroupName

foreach ($groupBatch in $groupedRows) {
    $groupName = $groupBatch.Name
    $requestedMembers = $groupBatch.Group | Select-Object -ExpandProperty SamAccountName

    Write-Host "`nProcessing group '$groupName' ($($requestedMembers.Count) requested member(s))..." -ForegroundColor Cyan

    # Confirm the target group exists before attempting any membership change
    try {
        Get-ADGroup -Identity $groupName -ErrorAction Stop | Out-Null
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "FAIL: group '$groupName' does not exist. Skipping this group's batch." -ForegroundColor Red
        continue
    }
    catch {
        Write-Host "ERROR: could not query group '$groupName' ($($_.Exception.Message)). Skipping this group's batch." -ForegroundColor Red
        continue
    }

    # Pre-validate each requested member individually; Add-ADGroupMember validates its
    # entire -Members array before making any change, so one bad name blocks every
    # valid member in the same call (confirmed against Test-BulkAdd-Verify)
    $validMembers = @()
    foreach ($member in $requestedMembers) {
        try {
            Get-ADUser -Identity $member -ErrorAction Stop | Out-Null
            $validMembers += $member
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Host "FAIL: '$member' does not exist; excluded from this group's batch." -ForegroundColor Red
        }
        catch {
            Write-Host "ERROR: could not query '$member' ($($_.Exception.Message)); excluded from this group's batch." -ForegroundColor Red
        }
    }

    if ($validMembers.Count -eq 0) {
        Write-Host "FAIL: no valid members remain for '$groupName'; nothing to add." -ForegroundColor Red
        continue
    }

    Write-Host "Adding $($validMembers.Count) validated member(s) to '$groupName'..." -ForegroundColor Cyan
    Add-ADGroupMember -Identity $groupName -Members $validMembers

    # Validate the result by querying the group's membership back, rather than trusting the call above
    $currentMembers = Get-ADGroupMember -Identity $groupName | Select-Object -ExpandProperty SamAccountName

    foreach ($member in $validMembers) {
        if ($currentMembers -contains $member) {
            Write-Host "PASS: '$member' is a member of '$groupName'." -ForegroundColor Green
        }
        else {
            Write-Host "FAIL: '$member' was not found in '$groupName' after the add." -ForegroundColor Red
        }
    }
}
