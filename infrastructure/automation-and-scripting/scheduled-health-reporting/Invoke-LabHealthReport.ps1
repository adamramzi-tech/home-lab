<#
.SYNOPSIS
    Orchestrates the three Lab 05 health checks (AD service health, Wazuh
    agent status, Docker service status), aggregates their results with a
    worst-wins rule, and produces a console table on interactive runs plus
    an always-written timestamped HTML report.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Five. This is the script Step Six will register as a
    Windows Task Scheduler job on WIN11-CLIENT01, so it is the environment's
    single entry point: an operator, or a scheduled firing, runs this one
    script, not the three check scripts individually.

    Per Design Decision 2, the orchestrator is deliberately thin. It does
    not re-implement any per-check classification; each check script owns
    its own Healthy/Unhealthy/Unknown determination for its own data
    source, and this script only calls the three check functions, applies
    the worst-wins aggregation from Design Decision 4, and handles the two
    output shapes from Design Decision 3. It relies entirely on each
    check's own defaults (target host and service list, Wazuh base URI and
    agent list, Portainer base URI, endpoint ID, and expected-container
    list) rather than re-declaring any of them here; this script's own
    parameters are the two credentials it must supply, -WazuhCredential and
    -PortainerCredential, and -ReportDirectory for the report output. Base
    URI pass-through parameters were considered, per Design Decision 2's
    "may expose... if it stays thin" allowance, and deliberately left out:
    none of the three checks' base URIs have changed since Steps Two
    through Four, and adding pass-through parameters for values nothing in
    this lab currently needs to override would be scope this script does
    not need to carry.

    Dot-source placement is a correctness requirement here, not a style
    choice, per Design Decision 6. The three check scripts are dot-sourced
    once, at this file's own top level (resolved relative to
    $PSScriptRoot), rather than inside the Invoke-LabHealthReport function
    body. Placed at the top level, the three check functions
    (Get-LabADServiceHealth, Get-LabWazuhAgentStatus,
    Get-LabDockerServiceStatus) are defined exactly once, when this file
    itself is loaded, whether by dot-sourcing or by a direct run; a Pester
    suite can then dot-source this file (which dot-sources the three
    checks and defines the real functions), Mock those three functions by
    name, and invoke Invoke-LabHealthReport, and the mocks take effect
    because PowerShell resolves a bare function call by name at call time.
    Had the dot-source calls instead lived inside the Invoke-LabHealthReport
    function body, every call to that function would re-dot-source the
    three check scripts and redefine the real functions over top of any
    active Mock, making the aggregation untestable; this is why the
    placement below is load-time, top-level, and outside the function.

    Parameter-name collision is handled by naming, not by scoping. Because
    the three check scripts are dot-sourced into this file's own scope,
    each check script's own top-level param block variables ($ComputerName,
    $ServiceName, $BaseUri, $Credential, $AgentName, $EndpointId,
    $ExpectedContainer, $ExportPath) are bound into this scope as a side
    effect, using each check's own defaults, the last-dot-sourced script's
    value winning for any name more than one check script happens to share
    (for example $BaseUri, set first by Get-LabWazuhAgentStatus.ps1 and
    then overwritten by Get-LabDockerServiceStatus.ps1's own default).
    None of that is used by this script; this script's own parameters are
    named -WazuhCredential, -PortainerCredential, and -ReportDirectory
    specifically so that none of them collides with any name the three
    dot-sourced check scripts already bind, rather than scoping the
    dot-source calls to prevent the collision.

    As in every check script in this lab, the top-level -WazuhCredential
    and -PortainerCredential parameters carry no Mandatory attribute and no
    default, and neither does -ReportDirectory: a Mandatory parameter at
    the top of this file would make PowerShell prompt for it the moment
    the file is dot-sourced, which would hang a Pester run waiting on
    input rather than merely defining the function. The standalone path
    inside the guard at the bottom of this file prompts for whichever of
    the three is missing, Get-Credential for the two credentials and
    Read-Host for the report directory, only when this file is run
    directly.

    Aggregation (Design Decision 4, worst-wins): if any of the three
    checks reports Unhealthy, the overall status is Unhealthy, regardless
    of the other two; else if any check reports Unknown, the overall
    status is Unknown; only if all three report Healthy is the overall
    status Healthy. This is pure logic with no external dependency of its
    own, and it is this lab's highest-value Pester target per Design
    Decision 6: the suite alongside this script exercises it against every
    combination of the three checks' three possible states, twenty-seven
    in total, by mocking the three check functions by name rather than
    their underlying cmdlets.

    Report output (Design Decision 3): a console table (CheckName and
    Status for the three checks, plus the aggregated Overall row) is
    printed on an interactive run, and a timestamped, self-contained HTML
    summary is always written to -ReportDirectory, on every run, whether
    invoked by an operator or, once Step Six registers it, by Task
    Scheduler. An HTML summary was chosen over a flat CSV row, the same
    departure Get-LabDockerServiceStatus.ps1's own precedent set for
    Design Decision 3's text, because three different check types rolled
    into one overall status does not reduce cleanly to a single flat row.
    The report file is an exported artifact, not a repository file: it is
    written only to the runtime -ReportDirectory the operator supplies.

    Credential and token hygiene. -WazuhCredential and -PortainerCredential
    are accepted as [PSCredential], the same discipline every credential in
    this lab uses, and are passed straight through to the two REST-backed
    checks without ever being read from, echoed, or stored by this script.
    The three check functions already exclude their own credentials and
    JWTs from their returned objects, per Steps Three and Four's own
    hygiene; this script's console table and HTML report both render only
    CheckName and Status values drawn from those already-clean returned
    objects, so neither surface can carry a credential or a token forward.
    The Pester suite asserts this directly rather than assuming it.

    A testability boundary worth stating plainly: because the three check
    scripts are dot-sourced unconditionally at this file's own top level,
    running this file directly (for example, `& .\Invoke-LabHealthReport.ps1`,
    as opposed to dot-sourcing it with a leading `.`) re-executes those
    three dot-source statements in that run's own local scope, which
    redefines the three check functions as their real, network-calling
    selves in that local scope, shadowing any Mock a caller further up the
    scope chain had set. This is why the console-table rendering below is
    factored into its own function, Get-LabHealthReportSummaryTable, which
    the Pester suite calls directly against a $result it already has from
    an already-mocked Invoke-LabHealthReport call, rather than by invoking
    this file directly with `&` the way the three check scripts' own test
    suites do for their console-output-hygiene assertions. The three check
    scripts do not have this issue, since none of them dot-sources anything
    else; this script does, and that is a direct consequence of Design
    Decision 6's own dot-source-for-mockability requirement.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [PSCredential]$WazuhCredential,

    [Parameter(Mandatory = $false)]
    [PSCredential]$PortainerCredential,

    [Parameter(Mandatory = $false)]
    [string]$ReportDirectory
)

# Dot-sourced once, at this file's own top level, per this step's
# dot-source-for-mockability decision described above. Resolved relative
# to $PSScriptRoot, matching this lab's per-lab subfolder convention: all
# four scripts are colocated in
# infrastructure/automation-and-scripting/scheduled-health-reporting/.
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-LabADServiceHealth.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-LabWazuhAgentStatus.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-LabDockerServiceStatus.ps1')

function ConvertTo-LabHealthReportHtml {
    # Named ConvertTo-, not New-: PSScriptAnalyzer's
    # PSUseShouldProcessForStateChangingFunctions rule treats New- as a
    # state-changing verb requiring ShouldProcess support, which this
    # function does not need, since it only builds and returns an HTML
    # string with no side effect of its own (the actual file write happens
    # in Invoke-LabHealthReport, via Out-File). ConvertTo- is the correct
    # verb for what this function actually does, converting the three
    # check results into an HTML representation, the same relationship
    # PowerShell's own ConvertTo-Html cmdlet has to the data it renders,
    # and it is not in PSScriptAnalyzer's state-changing-verb list, so the
    # rename resolves the finding rather than suppressing it.
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [datetime]$Timestamp,

        [Parameter(Mandatory = $true)]
        [string]$OverallStatus,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ADResult,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$WazuhResult,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DockerResult
    )

    # Every rendered value, including a check's own Message text (drawn
    # from an exception's message on an Unknown result), is HTML-encoded
    # before being embedded below. Neither a credential object nor a JWT
    # ever reaches this function: the three check results already exclude
    # both, per Steps Three and Four's own hygiene, so there is nothing
    # here to redact, only to encode safely.
    $adRows = if (@($ADResult.Services).Count -gt 0) {
        (@($ADResult.Services) | ForEach-Object {
            $encodedName = [System.Net.WebUtility]::HtmlEncode([string]$_.ServiceName)
            $encodedStatus = [System.Net.WebUtility]::HtmlEncode([string]$_.Status)
            "<tr><td>$encodedName</td><td>$encodedStatus</td></tr>"
        }) -join "`n"
    }
    else {
        $encodedStatus = [System.Net.WebUtility]::HtmlEncode([string]$ADResult.Status)
        "<tr><td colspan=""2"">(no services returned; check status: $encodedStatus)</td></tr>"
    }

    $wazuhRows = if (@($WazuhResult.Agents).Count -gt 0) {
        (@($WazuhResult.Agents) | ForEach-Object {
            $encodedName = [System.Net.WebUtility]::HtmlEncode([string]$_.AgentName)
            $encodedStatus = [System.Net.WebUtility]::HtmlEncode([string]$_.Status)
            "<tr><td>$encodedName</td><td>$encodedStatus</td></tr>"
        }) -join "`n"
    }
    else {
        $encodedStatus = [System.Net.WebUtility]::HtmlEncode([string]$WazuhResult.Status)
        "<tr><td colspan=""2"">(no agents returned; check status: $encodedStatus)</td></tr>"
    }

    $dockerRows = if (@($DockerResult.Containers).Count -gt 0) {
        (@($DockerResult.Containers) | ForEach-Object {
            $encodedName = [System.Net.WebUtility]::HtmlEncode([string]$_.ContainerName)
            $encodedState = [System.Net.WebUtility]::HtmlEncode([string]$_.State)
            "<tr><td>$encodedName</td><td>$encodedState</td></tr>"
        }) -join "`n"
    }
    else {
        $encodedStatus = [System.Net.WebUtility]::HtmlEncode([string]$DockerResult.Status)
        "<tr><td colspan=""2"">(no containers returned; check status: $encodedStatus)</td></tr>"
    }

    $adClass = 'status-{0}' -f $ADResult.Status.ToLowerInvariant()
    $wazuhClass = 'status-{0}' -f $WazuhResult.Status.ToLowerInvariant()
    $dockerClass = 'status-{0}' -f $DockerResult.Status.ToLowerInvariant()
    $overallClass = 'status-{0}' -f $OverallStatus.ToLowerInvariant()

    $adMessage = if ($ADResult.Message) { [System.Net.WebUtility]::HtmlEncode([string]$ADResult.Message) } else { '' }
    $wazuhMessage = if ($WazuhResult.Message) { [System.Net.WebUtility]::HtmlEncode([string]$WazuhResult.Message) } else { '' }
    $dockerMessage = if ($DockerResult.Message) { [System.Net.WebUtility]::HtmlEncode([string]$DockerResult.Message) } else { '' }

    $generatedAt = [System.Net.WebUtility]::HtmlEncode($Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))

    @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Lab Health Report - $generatedAt</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; margin: 2rem; color: #1a1a1a; }
  h1 { font-size: 1.4rem; }
  h2 { font-size: 1.1rem; margin-top: 2rem; }
  table { border-collapse: collapse; width: 100%; max-width: 700px; margin-top: 0.5rem; }
  th, td { border: 1px solid #ccc; padding: 0.4rem 0.6rem; text-align: left; }
  th { background: #f0f0f0; }
  .status-healthy { color: #1a7f37; font-weight: bold; }
  .status-unhealthy { color: #c0392b; font-weight: bold; }
  .status-unknown { color: #b8860b; font-weight: bold; }
  .overall { font-size: 1.2rem; margin: 1rem 0; }
</style>
</head>
<body>
<h1>Lab Health Report</h1>
<p>Generated: $generatedAt</p>
<p class="overall">Overall status: <span class="$overallClass">$OverallStatus</span></p>

<h2>ADServiceHealth <span class="$adClass">($($ADResult.Status))</span></h2>
<table>
<tr><th>Service</th><th>Status</th></tr>
$adRows
</table>
$(if ($adMessage) { "<p>Message: $adMessage</p>" })

<h2>WazuhAgentStatus <span class="$wazuhClass">($($WazuhResult.Status))</span></h2>
<table>
<tr><th>Agent</th><th>Status</th></tr>
$wazuhRows
</table>
$(if ($wazuhMessage) { "<p>Message: $wazuhMessage</p>" })

<h2>DockerServiceStatus <span class="$dockerClass">($($DockerResult.Status))</span></h2>
<table>
<tr><th>Container</th><th>State</th></tr>
$dockerRows
</table>
$(if ($dockerMessage) { "<p>Message: $dockerMessage</p>" })

</body>
</html>
"@
}

function Get-LabHealthReportSummaryTable {
    [CmdletBinding()]
    [OutputType([System.Array])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Result
    )

    @(
        [PSCustomObject]@{ CheckName = $Result.ADServiceHealth.CheckName; Status = $Result.ADServiceHealth.Status }
        [PSCustomObject]@{ CheckName = $Result.WazuhAgentStatus.CheckName; Status = $Result.WazuhAgentStatus.Status }
        [PSCustomObject]@{ CheckName = $Result.DockerServiceStatus.CheckName; Status = $Result.DockerServiceStatus.Status }
        [PSCustomObject]@{ CheckName = 'Overall'; Status = $Result.OverallStatus }
    )
}

function Invoke-LabHealthReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCredential]$WazuhCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential]$PortainerCredential,

        [Parameter(Mandatory = $true)]
        [string]$ReportDirectory
    )

    $adResult = Get-LabADServiceHealth
    $wazuhResult = Get-LabWazuhAgentStatus -Credential $WazuhCredential
    $dockerResult = Get-LabDockerServiceStatus -Credential $PortainerCredential

    # Worst-wins aggregation, per Design Decision 4: any Unhealthy check
    # makes the overall status Unhealthy regardless of the other two;
    # failing that, any Unknown check makes it Unknown; only if all three
    # report Healthy is the overall status Healthy.
    $checkStatuses = @($adResult.Status, $wazuhResult.Status, $dockerResult.Status)

    if ($checkStatuses -contains 'Unhealthy') {
        $overallStatus = 'Unhealthy'
    }
    elseif ($checkStatuses -contains 'Unknown') {
        $overallStatus = 'Unknown'
    }
    else {
        $overallStatus = 'Healthy'
    }

    if (-not (Test-Path -Path $ReportDirectory)) {
        New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date
    $reportFileName = 'LabHealthReport-{0}.html' -f $timestamp.ToString('yyyyMMdd-HHmmss')
    $reportPath = Join-Path -Path $ReportDirectory -ChildPath $reportFileName

    $html = ConvertTo-LabHealthReportHtml -Timestamp $timestamp -OverallStatus $overallStatus `
        -ADResult $adResult -WazuhResult $wazuhResult -DockerResult $dockerResult

    $html | Out-File -FilePath $reportPath -Encoding utf8

    [PSCustomObject]@{
        Timestamp           = $timestamp
        OverallStatus       = $overallStatus
        ADServiceHealth     = $adResult
        WazuhAgentStatus    = $wazuhResult
        DockerServiceStatus = $dockerResult
        ReportPath          = $reportPath
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $WazuhCredential) {
        $WazuhCredential = Get-Credential -Message 'Wazuh Manager API credentials (wazuh-wui)'
    }

    # Get-Credential returns $null if the prompt is cancelled (Cancel or
    # Esc), rather than throwing. Checked explicitly here, immediately
    # after the prompt, rather than letting a $null credential reach
    # Get-LabWazuhAgentStatus, where it would fail deep inside that
    # function's own REST calls with a much less obvious error.
    if (-not $WazuhCredential) {
        throw 'A Wazuh Manager API credential is required to run this report; the credential prompt was cancelled or left empty.'
    }

    if (-not $PortainerCredential) {
        $PortainerCredential = Get-Credential -Message 'Portainer admin API credentials'
    }

    if (-not $PortainerCredential) {
        throw 'A Portainer admin API credential is required to run this report; the credential prompt was cancelled or left empty.'
    }

    if (-not $ReportDirectory) {
        $ReportDirectory = Read-Host -Prompt 'Report directory (e.g. C:\Reports)'
    }

    # Read-Host returns an empty string, not $null, when the operator
    # presses Enter without typing anything. Checked explicitly here: an
    # empty string passed through to Invoke-LabHealthReport's own
    # Mandatory [string]$ReportDirectory parameter fails PowerShell's
    # built-in empty-string-not-allowed parameter validation, and that
    # failure is a non-terminating error at the script level, meaning
    # execution would otherwise continue past it with $result still
    # $null, rendering a blank summary table and reporting no report
    # path instead of stopping cleanly. Confirmed by an operator's real
    # run against an earlier version of this file that had no such
    # check.
    if ([string]::IsNullOrWhiteSpace($ReportDirectory)) {
        throw 'A report directory is required to run this report; the prompt was left empty.'
    }

    $result = Invoke-LabHealthReport -WazuhCredential $WazuhCredential -PortainerCredential $PortainerCredential -ReportDirectory $ReportDirectory

    Get-LabHealthReportSummaryTable -Result $result | Format-Table -AutoSize

    Write-Output "Report written to: $($result.ReportPath)"
}
