<#
.SYNOPSIS
    Queries the Wazuh Manager REST API for the enrollment and connectivity
    status of the environment's monitored agents and classifies the result
    as Healthy, Unhealthy, or Unknown.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Three. Run from WIN11-CLIENT01 against the Wazuh
    Manager API at 192.168.1.226:55000, per Design Decision 1; authenticates
    with the Manager API's own dedicated wazuh-wui account (confirmed in
    Implementation Step One, distinct from the Dashboard/Indexer login) and
    queries GET /agents over the JWT the authentication call returns.

    Read-only: makes no Wazuh configuration or agent state changes anywhere.
    DC01, WIN11-CLIENT01, and UBUNTU-SERVER (the three agents Step One
    confirmed enrolled and active) are checked by default; both the Manager
    base URI and the target agent list can be overridden.

    Per this lab's Design Decision 2, this script defines a function named
    the same as the file, Get-LabWazuhAgentStatus, copying the dot-sourced-
    function invocation model Get-LabADServiceHealth.ps1 (Step Two)
    established, so Invoke-LabHealthReport.ps1 (Step Five) can dot-source
    this file and call the function by name rather than executing it as a
    separate process. That invocation model carries the same hard
    requirement Step Two's script had to satisfy: dot-sourcing this file
    must define the function with no side effects, no call against the
    Wazuh API and no console output. The same guard idiom is used at the
    bottom of the script, `if ($MyInvocation.InvocationName -ne '.') { ... }`,
    and the standalone console-table-plus-optional-`-ExportPath` rendering
    from Design Decision 3 lives entirely inside it. The Pester suite
    alongside this script (Get-LabWazuhAgentStatus.Tests.ps1) asserts that
    guard directly.

    One consequence of that no-side-effects requirement is that the top-level
    -Credential parameter below carries no Mandatory attribute and no
    default, even though the function it eventually calls requires one: a
    Mandatory parameter at the top of the script would make PowerShell
    prompt for it the moment the file is dot-sourced, which would hang a
    test run waiting on interactive input rather than merely defining the
    function. The standalone path inside the guard prompts for the
    credential itself, with Get-Credential, only when the file is actually
    run directly and no -Credential was supplied.

    Per Design Decision 4, classification is: Healthy if every named agent
    is present in the API response and reports active; Unhealthy if the
    query completes but any named agent reports a non-active status
    (disconnected, never_connected, pending, or any other value besides
    active) or is missing from the response entirely, the Wazuh-agent
    analog of Get-LabADServiceHealth.ps1's NotFound condition; Unknown only
    if authentication or the agent query itself could not be completed.

    Unlike Get-Service, which Step Two discovered does not throw a
    terminating error for an unreachable target when called with -Name,
    forcing Get-LabADServiceHealth.ps1 into the enumerate-then-match rework
    documented in that step's Troubleshooting, Invoke-RestMethod throws a
    terminating error on its own for both a connection failure and an HTTP
    error status such as the 401 Step One's own troubleshooting produced
    against the wrong Wazuh account. A failed authentication or an
    unreachable Manager API therefore reaches this script's try/catch and
    classifies Unknown without any equivalent workaround: the same Unknown
    requirement Step Two had to engineer around Get-Service's actual
    behavior is satisfied here by Invoke-RestMethod's own throwing
    behavior, confirmed by this script's mocked Pester coverage rather than
    assumed.

    GET /agents returns a fourth entry for the Wazuh Manager's own built-in
    agent (id 000, name wazuh.manager) alongside the three monitored
    targets, confirmed in Implementation Step One. This script excludes
    that entry before matching against the requested -AgentName list, so it
    is never counted as a monitored agent and never affects the returned
    Status, whatever its own reported status happens to be.

    Certificate-validation bypass (Design Decision 2 for this step).
    PowerShell 5.1's Invoke-RestMethod has no -SkipCertificateCheck
    parameter, so reaching the Wazuh stack's self-signed certificate over
    HTTPS requires the same TLS 1.2 / TrustAllCertsPolicy accommodation
    Step One used interactively. That accommodation is process-wide in
    PowerShell 5.1: [System.Net.ServicePointManager]::CertificatePolicy has
    no narrower, request-scoped equivalent. Step One's own Security
    Considerations left open how the finished script should handle this;
    the decision made here is to capture the process's existing
    CertificatePolicy and SecurityProtocol before applying the
    accommodation, apply it only for the authentication and agent-query
    calls this function makes, and restore both original values in a
    finally block so certificate validation is disabled only for the
    duration of this function's own REST calls, not for the rest of the
    calling session. Restoring cleanly is not impractical here: both
    ServicePointManager properties are ordinary settable static properties,
    and saving and reassigning them costs nothing beyond the two extra
    lines below.

    Credential and token hygiene. -Credential is accepted as a
    [PSCredential], per this track's established discipline for secrets
    (New-LabUser.ps1, Lab 01, took its password as a SecureString rather
    than plaintext); the Basic authentication header built from it, and the
    JWT bearer token GET /agents is authenticated with, exist only inside
    this function's local scope and are never written to the console, never
    placed on the returned object, and never included in the standalone
    report. The returned PSCustomObject carries only agent names and
    statuses, the overall Status, and a Message drawn from the exception's
    own text on failure, none of which includes the credential or the
    token. The Pester suite asserts this directly rather than assuming it.

    This script returns a PSCustomObject rather than printing PASS/FAIL
    narration with Write-Host, matching Get-LabADServiceHealth.ps1's
    convention. The standalone path below flattens the nested Agents
    collection to one row per agent, both for the Format-Table console
    output and, when -ExportPath is supplied, for Export-Csv.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$BaseUri = 'https://192.168.1.226:55000',

    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string[]]$AgentName = @('DC01', 'WIN11-CLIENT01', 'UBUNTU-SERVER'),

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

function Get-LabWazuhAgentStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BaseUri = 'https://192.168.1.226:55000',

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string[]]$AgentName = @('DC01', 'WIN11-CLIENT01', 'UBUNTU-SERVER')
    )

    # Captured before the accommodation below is applied, so both can be
    # restored once this function's own REST calls are done, per the
    # certificate-validation-bypass decision described above.
    $originalCertificatePolicy = [System.Net.ServicePointManager]::CertificatePolicy
    $originalSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol

    try {
        if (-not ('TrustAllCertsPolicy' -as [type])) {
            Add-Type @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest req, int problem) {
        return true;
    }
}
'@
        }

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

        $pair = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
        $base64Pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
        $authHeaders = @{ Authorization = "Basic $base64Pair" }

        $authResponse = Invoke-RestMethod -Uri "$BaseUri/security/user/authenticate" -Method Post -Headers $authHeaders -ErrorAction Stop
        $token = $authResponse.data.token

        $agentsHeaders = @{ Authorization = "Bearer $token" }
        $agentsResponse = Invoke-RestMethod -Uri "$BaseUri/agents" -Method Get -Headers $agentsHeaders -ErrorAction Stop
        $allAgents = @($agentsResponse.data.affected_items)
    }
    catch {
        return [PSCustomObject]@{
            CheckName = 'WazuhAgentStatus'
            BaseUri   = $BaseUri
            Agents    = @()
            Status    = 'Unknown'
            Message   = $_.Exception.Message
        }
    }
    finally {
        [System.Net.ServicePointManager]::CertificatePolicy = $originalCertificatePolicy
        [System.Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
    }

    # Agent 000 (wazuh.manager) is the Manager's own built-in agent, always
    # present in GET /agents per Step One; excluded here so it is never
    # treated as one of the monitored targets below.
    $monitoredAgents = $allAgents | Where-Object { $_.id -ne '000' }

    $overallStatus = 'Healthy'
    $agents = @()

    foreach ($name in $AgentName) {
        $matched = $monitoredAgents | Where-Object { $_.name -eq $name } | Select-Object -First 1

        if ($matched) {
            $agents += [PSCustomObject]@{
                AgentName = $name
                Status    = $matched.status
            }

            if ($matched.status -ne 'active') {
                $overallStatus = 'Unhealthy'
            }
        }
        else {
            $agents += [PSCustomObject]@{
                AgentName = $name
                Status    = 'NotFound'
            }
            $overallStatus = 'Unhealthy'
        }
    }

    [PSCustomObject]@{
        CheckName = 'WazuhAgentStatus'
        BaseUri   = $BaseUri
        Agents    = $agents
        Status    = $overallStatus
        Message   = $null
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $Credential) {
        $Credential = Get-Credential -Message 'Wazuh Manager API credentials (wazuh-wui)'
    }

    $result = Get-LabWazuhAgentStatus -BaseUri $BaseUri -Credential $Credential -AgentName $AgentName

    if ($result.Agents.Count -gt 0) {
        $rows = foreach ($agent in $result.Agents) {
            [PSCustomObject]@{
                CheckName     = $result.CheckName
                BaseUri       = $result.BaseUri
                AgentName     = $agent.AgentName
                AgentStatus   = $agent.Status
                OverallStatus = $result.Status
                Message       = $result.Message
            }
        }
    }
    else {
        $rows = [PSCustomObject]@{
            CheckName     = $result.CheckName
            BaseUri       = $result.BaseUri
            AgentName     = $null
            AgentStatus   = $null
            OverallStatus = $result.Status
            Message       = $result.Message
        }
    }

    $rows | Format-Table -AutoSize

    if ($ExportPath) {
        $rows | Export-Csv -Path $ExportPath -NoTypeInformation
    }
}
