<#
.SYNOPSIS
    Generates a Resultant Set of Policy (RSoP) report, in logging mode, for
    a specified user and computer.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 04 (Group Policy
    Reporting and Audit). Run from WIN11-CLIENT01 via RSAT against DC01, per
    ADR-016.

    Read-only: makes no changes to Group Policy. This is a thin wrapper
    around Get-GPResultantSetOfPolicy's native -ReportType Html/Xml
    logging-mode report, per this lab's Design Decisions: RSoP data is
    hierarchical and does not reduce cleanly to a console table the way the
    other two Lab 04 scripts' data does, so this script departs from their
    console-table-plus-CSV convention and simply hands its parameters
    through to the cmdlet and writes the resulting report file.

    This lab's open question, whether Get-GPResultantSetOfPolicy in logging
    mode requires the target user to have a prior interactive session on
    WIN11-CLIENT01, was resolved by a live diagnostic during Step Four, not
    assumed:

    - Running non-elevated, the cmdlet failed for every user tested,
      including the account running the session itself: a COMException
      (HRESULT 0x80041003, WBEM_E_ACCESS_DENIED) for the currently
      logged-on user (labadmin), and a NoLoggingData ArgumentException for
      a user with no prior session on the client at all (jsmith).
    - Running elevated (Run as Administrator), the cmdlet succeeded for
      both the currently logged-on user (labadmin) and a user who was NOT
      currently logged on but had a prior interactive session on the
      client from enterprise Lab 05 (testuser01), each returning
      RsopMode: Logging with LoggingMode: UserAndComputer.

    This confirms the plan's original wording: the requirement is a PRIOR
    interactive session, not a currently active one, but only once the
    session generating the report is elevated. A user with no session
    history at all on the client is expected to still fail regardless of
    elevation, that specific combination was not independently re-tested
    elevated during this lab, since the non-elevated NoLoggingData failure
    already isolated the cause to missing logging data rather than
    permissions. gpresult /r and gpresult /h, run interactively as that
    user, remain the documented fallback for that case, per the plan.

    Because the cmdlet's own failure mode is a terminating exception whose
    message is not actionable at a glance (a raw COMException or
    ArgumentException), this script wraps the call in a try/catch and
    reports a message pointing at the two known causes (non-elevation, or
    no cached RSoP data for that user on that computer) and the gpresult
    fallback, rather than letting the raw exception surface.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$User,

    [Parameter(Mandatory = $true)]
    [string]$Computer,

    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Html', 'Xml')]
    [string]$ReportType = 'Html'
)

Import-Module GroupPolicy

Write-Host "Generating $ReportType RSoP report for '$User' on '$Computer'..." -ForegroundColor Cyan

try {
    Get-GPResultantSetOfPolicy -ReportType $ReportType -Path $Path -User $User -Computer $Computer -ErrorAction Stop
    Write-Host "RSoP report written to '$Path'." -ForegroundColor Green
}
catch {
    Write-Host "FAIL: could not generate an RSoP report for '$User' on '$Computer' ($($_.Exception.Message))." -ForegroundColor Red
    Write-Host "This can happen if this session is not elevated (Run as Administrator), or if '$User' has no prior interactive session on '$Computer' with cached RSoP logging data. Use 'gpresult /r' or 'gpresult /h', run interactively as '$User', as a fallback." -ForegroundColor Yellow
}
