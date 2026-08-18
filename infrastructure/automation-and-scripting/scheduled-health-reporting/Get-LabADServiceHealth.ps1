<#
.SYNOPSIS
    Checks the running state of a defined set of Active Directory-related
    Windows services on DC01 and classifies the result as Healthy,
    Unhealthy, or Unknown.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Two. Run from WIN11-CLIENT01 against DC01, per
    ADR-016; queries Get-Service -ComputerName, confirmed in Implementation
    Step One to require no elevation and no new remoting technology.

    Read-only: makes no service state changes anywhere. NTDS, DNS,
    Netlogon, Kdc, W32Time, and ADWS (the six services confirmed Running
    against DC01 in Step One) are queried by default; both the target
    computer and the service list can be overridden.

    Per this lab's Design Decision 2, this script defines a function named
    the same as the file, Get-LabADServiceHealth, so Invoke-LabHealthReport.ps1
    (Step Five) can dot-source this file and call the function by name
    rather than executing it as a separate process, which is what makes the
    orchestrator's aggregation logic mockable under Design Decision 6.
    That invocation model creates a hard requirement this script has to
    satisfy, and which every later check script in this lab (Steps Three
    and Four) is expected to copy: dot-sourcing this file must define the
    function with no side effects, it must not query DC01 or print
    anything. The idiom used here is a guard at the bottom of the script,
    `if ($MyInvocation.InvocationName -ne '.') { ... }`, which is true when
    the file is run directly (`.\Get-LabADServiceHealth.ps1`) and false
    when it is dot-sourced (`. .\Get-LabADServiceHealth.ps1`); the standalone
    console-table-plus-optional-`-ExportPath` rendering from Design
    Decision 3 lives entirely inside that guard, so dot-sourcing only ever
    defines the function and the top-level parameter defaults, never runs
    the check or writes output. The Pester suite alongside this script
    (Get-LabADServiceHealth.Tests.ps1) asserts that guard directly.

    Per Design Decision 4, classification is: Healthy if every named
    service reports Running; Unhealthy if the query completes but any
    named service is not Running, including a named service that is not
    present on the target at all, which is a real "expected service
    absent" condition rather than a query failure; Unknown only if the
    query itself could not be completed (host unreachable, an RPC/SCM
    error, access denied, or any other failure to open the Service Control
    Manager on the target), caught in a try/catch.

    The query enumerates every service on the target with
    Get-Service -ComputerName $ComputerName -ErrorAction Stop, deliberately
    without -Name, and this script matches each requested name against the
    returned collection itself. That shape is a correctness requirement,
    not a stylistic choice, and it was settled by live diagnostic rather
    than assumption (recorded in this lab's Step Two Troubleshooting). The
    script originally passed -Name with -ErrorAction SilentlyContinue on the
    assumption that a connectivity or permission failure would throw a
    terminating exception regardless of -ErrorAction preference and so still
    reach the catch. A live run against an unreachable target showed that
    assumption was wrong: Get-Service -ComputerName -Name emits one
    non-terminating "Cannot find any service with service name 'X'"
    ServiceCommandException per requested name, the same error type an
    absent-but-reachable service produces, and -ErrorAction SilentlyContinue
    suppressed all of them before the catch could see anything, leaving an
    empty result that was misclassified Unhealthy (every service NotFound)
    instead of Unknown. Enumerating without -Name keeps the two conditions
    distinct: a target whose Service Control Manager cannot be opened raises
    a single terminating InvalidOperationException ("Cannot open Service
    Control Manager on computer ...") that -ErrorAction Stop routes to the
    catch, classified Unknown with the exception message carried on the
    returned object; an absent named service on a reachable host is simply
    missing from the enumerated collection, and this script's own
    per-service match classifies that service NotFound and the check
    Unhealthy.

    This script returns a PSCustomObject rather than printing PASS/FAIL
    narration with Write-Host, so it does not rely on this library's
    PSAvoidUsingWriteHost suppression (Lab 03) to stay analyzer-clean: the
    standalone path below formats the returned object for the console with
    Format-Table and, when -ExportPath is supplied, Export-Csv, rather than
    writing status lines directly. Because the returned object nests a
    per-service collection under Services, which does not serialize
    cleanly to a single CSV row, the standalone path flattens it
    deliberately: one row per named service, each row repeating the check
    name, target, and overall status alongside that service's own name and
    status, both for the console table and for the CSV export.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = 'DC01',

    [Parameter(Mandatory = $false)]
    [string[]]$ServiceName = @('NTDS', 'DNS', 'Netlogon', 'Kdc', 'W32Time', 'ADWS'),

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

function Get-LabADServiceHealth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = 'DC01',

        [Parameter(Mandatory = $false)]
        [string[]]$ServiceName = @('NTDS', 'DNS', 'Netlogon', 'Kdc', 'W32Time', 'ADWS')
    )

    $services = @()

    try {
        $queried = @(Get-Service -ComputerName $ComputerName -ErrorAction Stop)
    }
    catch {
        return [PSCustomObject]@{
            CheckName    = 'ADServiceHealth'
            ComputerName = $ComputerName
            Services     = @()
            Status       = 'Unknown'
            Message      = $_.Exception.Message
        }
    }

    $overallStatus = 'Healthy'

    foreach ($name in $ServiceName) {
        $matched = $queried | Where-Object { $_.Name -eq $name } | Select-Object -First 1

        if ($matched) {
            $services += [PSCustomObject]@{
                ServiceName = $name
                Status      = $matched.Status.ToString()
            }

            if ($matched.Status -ne 'Running') {
                $overallStatus = 'Unhealthy'
            }
        }
        else {
            $services += [PSCustomObject]@{
                ServiceName = $name
                Status      = 'NotFound'
            }
            $overallStatus = 'Unhealthy'
        }
    }

    [PSCustomObject]@{
        CheckName    = 'ADServiceHealth'
        ComputerName = $ComputerName
        Services     = $services
        Status       = $overallStatus
        Message      = $null
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Get-LabADServiceHealth -ComputerName $ComputerName -ServiceName $ServiceName

    if ($result.Services.Count -gt 0) {
        $rows = foreach ($service in $result.Services) {
            [PSCustomObject]@{
                CheckName     = $result.CheckName
                ComputerName  = $result.ComputerName
                ServiceName   = $service.ServiceName
                ServiceStatus = $service.Status
                OverallStatus = $result.Status
                Message       = $result.Message
            }
        }
    }
    else {
        $rows = [PSCustomObject]@{
            CheckName     = $result.CheckName
            ComputerName  = $result.ComputerName
            ServiceName   = $null
            ServiceStatus = $null
            OverallStatus = $result.Status
            Message       = $result.Message
        }
    }

    $rows | Format-Table -AutoSize

    if ($ExportPath) {
        $rows | Export-Csv -Path $ExportPath -NoTypeInformation
    }
}
