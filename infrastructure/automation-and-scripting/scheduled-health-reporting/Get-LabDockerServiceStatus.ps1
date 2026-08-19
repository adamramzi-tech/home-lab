<#
.SYNOPSIS
    Queries the Portainer REST API for the running state of the Docker
    containers that make up the monitoring, reverse-proxy, and Wazuh stacks
    on Ubuntu Server, and classifies the result as Healthy, Unhealthy, or
    Unknown.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Four. Run from WIN11-CLIENT01 against Portainer's REST
    API, per Design Decision 1 (Option D); authenticates with the Portainer
    admin account against POST /api/auth and queries
    GET /api/endpoints/{id}/docker/containers/json?all=true over the JWT the
    authentication call returns.

    Read-only: makes no Docker configuration or container state changes
    anywhere. The base URI defaults to http://portainer.local, confirmed in
    Implementation Step One as the only working access path: Portainer has
    no direct LAN-accessible port (ADR-009; direct https://192.168.1.226:9443
    remains blocked), and the NGINX Proxy Manager proxy host for Portainer is
    HTTP-only, not HTTPS, with no SSL certificate assigned to that vhost.
    Unlike Get-LabWazuhAgentStatus.ps1 (Step Three), this script applies no
    TLS 1.2 / TrustAllCertsPolicy accommodation, since there is no HTTPS leg
    on this path to accommodate. One consequence, recorded in Security
    Considerations, is that the Portainer credential (and the JWT it
    produces) crosses the LAN in cleartext on every call this script makes,
    a reason a scheduled deployment would want a dedicated, least-privileged,
    read-only Portainer account rather than the broad admin account used
    here.

    The endpoint ID defaults to 3, the numeric Docker environment ID Step
    One confirmed live via GET /api/endpoints, not the previously assumed
    default of 1.

    Per this lab's Design Decision 2, this script defines a function named
    the same as the file, Get-LabDockerServiceStatus, copying the
    dot-sourced-function invocation model Get-LabADServiceHealth.ps1 (Step
    Two) and Get-LabWazuhAgentStatus.ps1 (Step Three) established, so
    Invoke-LabHealthReport.ps1 (Step Five) can dot-source this file and call
    the function by name rather than executing it as a separate process.
    That invocation model carries the same hard requirement the two earlier
    scripts had to satisfy: dot-sourcing this file must define the function
    with no side effects, no call against the Portainer API and no console
    output. The same guard idiom is used at the bottom of the script,
    `if ($MyInvocation.InvocationName -ne '.') { ... }`, and the standalone
    console-table-plus-optional-`-ExportPath` rendering from Design
    Decision 3 lives entirely inside it. As in Step Three, the top-level
    -Credential parameter below carries no Mandatory attribute and no
    default, even though the function it eventually calls requires one, so
    that dot-sourcing this file cannot hang a test run on an interactive
    prompt; the standalone path inside the guard prompts for the credential
    itself, with Get-Credential, only when the file is run directly and no
    -Credential was supplied.

    Docker's container-listing endpoint returns each container's Names as an
    array of strings with a leading slash (for example, ["/prometheus"]),
    confirmed in Step One's own container listing. This script normalizes
    that (takes the first entry and strips the leading slash) before
    matching a container against the -ExpectedContainer list; matching the
    raw, slash-prefixed value against a plain container name would silently
    fail every comparison.

    The containers query's response is a top-level JSON array, unlike the
    Wazuh agents query's response, which nests its array under a data
    property. This script's first live run surfaced a real correctness
    finding specific to that shape, recorded in this step's Troubleshooting:
    wrapping the live Invoke-RestMethod call for this endpoint directly in
    @() collected only one pipeline object, the entire ten-container array
    Invoke-RestMethod had written as a single object rather than one object
    per container, so @() nested that whole array as one element instead of
    flattening it into ten. The fix is to assign the response to a variable
    first and wrap that variable in @() rather than the live call itself;
    the containers query below does this.

    The default -ExpectedContainer set is the curated, expected-running
    baseline Step One established: the Wazuh stack
    (single-node-wazuh.manager-1, single-node-wazuh.indexer-1,
    single-node-wazuh.dashboard-1), the reverse proxy
    (nginx-proxy-manager), portainer itself, and the monitoring stack
    (prometheus, grafana, node-exporter). The docker-networking project's
    frontend and backend containers, leftover teaching-lab containers from
    linux infrastructure Lab 05, are deliberately not in this list, the same
    way Get-LabWazuhAgentStatus.ps1 excludes the Wazuh Manager's own agent
    000 from its target list: whatever their state, they are simply never
    matched against and never affect the result, rather than being detected
    and then special-cased.

    Per Design Decision 4, classification is: Healthy if every expected
    container is present in the API response and reports a running state;
    Unhealthy if the query completes but any expected container is present
    with a non-running state (its actual state is reported, for example
    exited) or is missing from the response entirely, reported NotFound, the
    Docker analog of Get-LabADServiceHealth.ps1's NotFound condition;
    Unknown only if authentication or the container query itself could not
    be completed. As with Get-LabWazuhAgentStatus.ps1, Invoke-RestMethod
    throws a terminating error on its own for both a connection failure and
    an HTTP error status, so a failed authentication or an unreachable
    Portainer API reaches this script's try/catch and classifies Unknown
    without the enumerate-then-match workaround Get-Service required in Step
    Two.

    As of Implementation Step One, the monitoring stack (prometheus,
    grafana, node-exporter) was found stopped, a genuine, previously
    undocumented outage that Step One deliberately left unremediated so this
    script's first live run would catch it. An Unhealthy result reporting
    those three containers exited, against a Running Wazuh stack,
    nginx-proxy-manager, and portainer, is this check working correctly on
    its first live run, not a defect in the script; remediation is deferred
    to Step Seven.

    Credential and token hygiene. -Credential is accepted as a
    [PSCredential], the same discipline every REST-backed check script in
    this lab uses. The JSON body POST /api/auth is authenticated with, and
    the JWT bearer token the containers query is authenticated with, exist
    only inside this function's local scope and are never written to the
    console, never placed on the returned object, and never included in the
    standalone report. The returned PSCustomObject carries only container
    names and states, the overall Status, and a Message drawn from the
    exception's own text on failure, none of which includes the credential
    or the token. The Pester suite asserts this directly rather than
    assuming it.

    This script returns a PSCustomObject rather than printing PASS/FAIL
    narration with Write-Host, matching the two earlier check scripts'
    convention. The standalone path below flattens the nested Containers
    collection to one row per expected container, both for the Format-Table
    console output and, when -ExportPath is supplied, for Export-Csv.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$BaseUri = 'http://portainer.local',

    [Parameter(Mandatory = $false)]
    [int]$EndpointId = 3,

    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string[]]$ExpectedContainer = @(
        'single-node-wazuh.manager-1',
        'single-node-wazuh.indexer-1',
        'single-node-wazuh.dashboard-1',
        'nginx-proxy-manager',
        'portainer',
        'prometheus',
        'grafana',
        'node-exporter'
    ),

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

function Get-LabDockerServiceStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BaseUri = 'http://portainer.local',

        [Parameter(Mandatory = $false)]
        [int]$EndpointId = 3,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string[]]$ExpectedContainer = @(
            'single-node-wazuh.manager-1',
            'single-node-wazuh.indexer-1',
            'single-node-wazuh.dashboard-1',
            'nginx-proxy-manager',
            'portainer',
            'prometheus',
            'grafana',
            'node-exporter'
        )
    )

    try {
        $authBody = @{
            Username = $Credential.UserName
            Password = $Credential.GetNetworkCredential().Password
        } | ConvertTo-Json

        $authResponse = Invoke-RestMethod -Uri "$BaseUri/api/auth" -Method Post -Body $authBody -ContentType 'application/json' -ErrorAction Stop
        $token = $authResponse.jwt

        $containersHeaders = @{ Authorization = "Bearer $token" }
        $containersUri = "$BaseUri/api/endpoints/$EndpointId/docker/containers/json?all=true"

        # Materialized into a variable first, then wrapped in @(), rather
        # than wrapping the live Invoke-RestMethod call directly. This
        # split is a correctness requirement, not a style choice: it was
        # settled by live diagnostic rather than assumption (recorded in
        # this lab's Step Four Troubleshooting). @() around a live cmdlet
        # call only collects whatever the cmdlet actually writes to the
        # pipeline; for this endpoint's top-level JSON array response,
        # Invoke-RestMethod writes the entire array as a single pipeline
        # object rather than one object per container, so
        # @(Invoke-RestMethod ...) wrapped that one object in another
        # array instead of flattening it, one nested array of ten
        # containers rather than ten containers. Assigning the response to
        # a variable first and then wrapping the variable does not have
        # this problem, since PowerShell's array-subexpression operator
        # enumerates an already-materialized array expression correctly.
        $containersResponse = Invoke-RestMethod -Uri $containersUri -Method Get -Headers $containersHeaders -ErrorAction Stop
        $allContainers = @($containersResponse)
    }
    catch {
        return [PSCustomObject]@{
            CheckName  = 'DockerServiceStatus'
            BaseUri    = $BaseUri
            EndpointId = $EndpointId
            Containers = @()
            Status     = 'Unknown'
            Message    = $_.Exception.Message
        }
    }

    # The Docker API reports each container's Names as an array with a
    # leading slash (for example, ["/prometheus"]); normalized here, before
    # matching against -ExpectedContainer, per Step One's own container
    # listing.
    $normalizedContainers = foreach ($container in $allContainers) {
        $rawName = @($container.Names) | Select-Object -First 1

        [PSCustomObject]@{
            Name  = $rawName -replace '^/', ''
            State = $container.State
        }
    }

    $overallStatus = 'Healthy'
    $containers = @()

    foreach ($name in $ExpectedContainer) {
        $matched = $normalizedContainers | Where-Object { $_.Name -eq $name } | Select-Object -First 1

        if ($matched) {
            $containers += [PSCustomObject]@{
                ContainerName = $name
                State         = $matched.State
            }

            if ($matched.State -ne 'running') {
                $overallStatus = 'Unhealthy'
            }
        }
        else {
            $containers += [PSCustomObject]@{
                ContainerName = $name
                State         = 'NotFound'
            }
            $overallStatus = 'Unhealthy'
        }
    }

    [PSCustomObject]@{
        CheckName  = 'DockerServiceStatus'
        BaseUri    = $BaseUri
        EndpointId = $EndpointId
        Containers = $containers
        Status     = $overallStatus
        Message    = $null
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $Credential) {
        $Credential = Get-Credential -Message 'Portainer admin API credentials'
    }

    $result = Get-LabDockerServiceStatus -BaseUri $BaseUri -EndpointId $EndpointId -Credential $Credential -ExpectedContainer $ExpectedContainer

    if ($result.Containers.Count -gt 0) {
        $rows = foreach ($container in $result.Containers) {
            [PSCustomObject]@{
                CheckName      = $result.CheckName
                BaseUri        = $result.BaseUri
                EndpointId     = $result.EndpointId
                ContainerName  = $container.ContainerName
                ContainerState = $container.State
                OverallStatus  = $result.Status
                Message        = $result.Message
            }
        }
    }
    else {
        $rows = [PSCustomObject]@{
            CheckName      = $result.CheckName
            BaseUri        = $result.BaseUri
            EndpointId     = $result.EndpointId
            ContainerName  = $null
            ContainerState = $null
            OverallStatus  = $result.Status
            Message        = $result.Message
        }
    }

    $rows | Format-Table -AutoSize

    if ($ExportPath) {
        $rows | Export-Csv -Path $ExportPath -NoTypeInformation
    }
}
