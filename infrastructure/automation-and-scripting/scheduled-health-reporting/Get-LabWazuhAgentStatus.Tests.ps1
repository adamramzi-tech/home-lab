<#
.SYNOPSIS
    Pester unit tests for Get-LabWazuhAgentStatus.ps1, using a mocked
    Invoke-RestMethod.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Three. Mocks Invoke-RestMethod, the only external
    command Get-LabWazuhAgentStatus.ps1 calls, so the suite runs without
    contacting the Wazuh Manager API, extending Lab 03's mocking pattern
    (already extended to Get-Service in Step Two) to the first
    Invoke-RestMethod-based check in this lab, per Design Decision 6.

    Get-LabWazuhAgentStatus.ps1 copies the dot-sourced-function invocation
    model Get-LabADServiceHealth.ps1 established in Step Two: the script
    file, dot-sourced, must define the Get-LabWazuhAgentStatus function with
    no side effects (no call against the Wazuh API, no console output), and
    only running the file directly is expected to invoke the function and
    render its result. The BeforeEach block below dot-sources the script
    before every test, both to make the function available to call directly
    for the classification tests and to give the dedicated 'Dot-sourcing
    behavior' Context a way to assert that the dot-source itself calls
    Invoke-RestMethod zero times.

    Because Get-LabWazuhAgentStatus (the function) returns its
    PSCustomObject result directly, the classification tests below call the
    function directly after dot-sourcing and assert on its returned Status,
    Agents, and Message properties, the same pattern Step Two's test suite
    used, rather than round-tripping through a CSV export.

    Invoke-RestMethod is called twice by a successful run: once to
    authenticate (POST .../security/user/authenticate) and once to query
    agents (GET .../agents). The two calls are distinguished in every
    ParameterFilter below by matching against the -Uri each call uses,
    since both calls are made against the same mocked command name.
    $PesterBoundParameters is used for every ParameterFilter and
    Should -Invoke -ParameterFilter below, per this lab's stated testing
    standard.

    Per Lab 03's own finding (PSAvoidUsingConvertToSecureStringWithPlainText,
    resolved in that lab by replacing a plaintext ConvertTo-SecureString
    call with an empty [System.Security.SecureString]::new()), the test
    credential built below never calls ConvertTo-SecureString with a
    plaintext string; it constructs a PSCredential directly from an empty
    SecureString, since none of the tests below depend on the password's
    actual contents, only on the credential object's presence.

    Run with:
        Invoke-Pester -Path .\Get-LabWazuhAgentStatus.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabWazuhAgentStatus.ps1'
    $script:DefaultAgentNames = @('DC01', 'WIN11-CLIENT01', 'UBUNTU-SERVER')
    $script:TestBaseUri = 'https://192.168.1.226:55000'
    $script:TestToken = 'fake-jwt-token-value'

    # Built without ConvertTo-SecureString -AsPlainText, per Lab 03's
    # PSAvoidUsingConvertToSecureStringWithPlainText finding: an empty
    # SecureString is sufficient, since no test below depends on the
    # password's actual contents.
    $script:TestCredential = [PSCredential]::new('wazuh-wui', [System.Security.SecureString]::new())

    # A reusable mocked Wazuh agent record, shared by every Context below.
    function script:New-MockAgent {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Id,

            [Parameter(Mandatory = $true)]
            [string]$Name,

            [Parameter(Mandatory = $false)]
            [string]$Status = 'active'
        )

        [PSCustomObject]@{
            id     = $Id
            name   = $Name
            status = $Status
        }
    }

    # The four-entry response Step One observed live: the manager's own
    # built-in agent (000) plus the three monitored targets, all active.
    function script:New-DefaultMockAgentSet {
        @(
            (New-MockAgent -Id '000' -Name 'wazuh.manager' -Status 'active'),
            (New-MockAgent -Id '001' -Name 'UBUNTU-SERVER' -Status 'active'),
            (New-MockAgent -Id '002' -Name 'WIN11-CLIENT01' -Status 'active'),
            (New-MockAgent -Id '003' -Name 'DC01' -Status 'active')
        )
    }

    function script:New-MockAuthResponse {
        [PSCustomObject]@{
            data = [PSCustomObject]@{ token = $script:TestToken }
        }
    }

    function script:New-MockAgentsResponse {
        param (
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$Agents
        )

        [PSCustomObject]@{
            data = [PSCustomObject]@{
                affected_items       = $Agents
                total_affected_items = $Agents.Count
            }
        }
    }
}

Describe 'Get-LabWazuhAgentStatus.ps1' {

    BeforeEach {
        # Default mocks: a successful authentication and a healthy
        # four-agent response (manager plus all three targets active),
        # overridden per It block below where the scenario under test needs
        # different data. Distinguished by -Uri, since both calls share the
        # same mocked command name.
        Mock -CommandName Invoke-RestMethod -ParameterFilter {
            $PesterBoundParameters['Uri'] -like '*/security/user/authenticate'
        } -MockWith { New-MockAuthResponse }

        Mock -CommandName Invoke-RestMethod -ParameterFilter {
            $PesterBoundParameters['Uri'] -like '*/agents'
        } -MockWith { New-MockAgentsResponse -Agents (New-DefaultMockAgentSet) }

        # Dot-source the script fresh for every test, so each test's
        # Get-LabWazuhAgentStatus function reflects the current file and no
        # state leaks between tests.
        . $script:ScriptPath
    }

    Context 'Dot-sourcing behavior' {

        It 'defines the Get-LabWazuhAgentStatus function without invoking a check' {
            Get-Command -Name Get-LabWazuhAgentStatus -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty

            Should -Invoke Invoke-RestMethod -Times 0
        }
    }

    Context 'Read-only behavior' {

        It 'calls Invoke-RestMethod only for the authenticate POST and the agents GET, nothing else' {
            Get-LabWazuhAgentStatus -Credential $script:TestCredential | Out-Null

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Method'] -eq 'Post' -and
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/security/user/authenticate"
            }

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Method'] -eq 'Get' -and
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/agents"
            }

            # No other call, of any method or against any other URI, was made.
            Should -Invoke Invoke-RestMethod -Times 2 -Exactly
        }
    }

    Context 'Classification: Healthy' {

        It 'reports Healthy when all three target agents are active' {
            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $result.Status | Should -Be 'Healthy'
            $result.Agents.Count | Should -Be 3
            ($result.Agents | Where-Object { $_.Status -ne 'active' }) | Should -BeNullOrEmpty
        }

        It 'excludes the manager''s own agent 000 from the result even though it is present in the response' {
            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            ($result.Agents | Where-Object { $_.AgentName -eq 'wazuh.manager' }) | Should -BeNullOrEmpty
            $result.Agents.Count | Should -Be 3
        }
    }

    Context 'Classification: Unhealthy' {

        It 'reports Unhealthy when the query completes but a target agent reports a non-active status' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/agents'
            } -MockWith {
                New-MockAgentsResponse -Agents @(
                    (New-MockAgent -Id '000' -Name 'wazuh.manager' -Status 'active'),
                    (New-MockAgent -Id '001' -Name 'UBUNTU-SERVER' -Status 'active'),
                    (New-MockAgent -Id '002' -Name 'WIN11-CLIENT01' -Status 'active'),
                    (New-MockAgent -Id '003' -Name 'DC01' -Status 'disconnected')
                )
            }

            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $result.Status | Should -Be 'Unhealthy'
            ($result.Agents | Where-Object { $_.AgentName -eq 'DC01' }).Status | Should -Be 'disconnected'
        }

        It 'reports Unhealthy when a target agent is missing from the response entirely' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/agents'
            } -MockWith {
                # UBUNTU-SERVER deliberately absent, simulating an agent that
                # never enrolled or was removed from the Manager's inventory.
                New-MockAgentsResponse -Agents @(
                    (New-MockAgent -Id '000' -Name 'wazuh.manager' -Status 'active'),
                    (New-MockAgent -Id '002' -Name 'WIN11-CLIENT01' -Status 'active'),
                    (New-MockAgent -Id '003' -Name 'DC01' -Status 'active')
                )
            }

            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $result.Status | Should -Be 'Unhealthy'
            ($result.Agents | Where-Object { $_.AgentName -eq 'UBUNTU-SERVER' }).Status | Should -Be 'NotFound'
        }

        It 'is unaffected by agent 000''s own status when all three targets are active' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/agents'
            } -MockWith {
                # The manager's own built-in agent reporting a non-active
                # status must not influence the result at all, since it is
                # never a monitored target.
                New-MockAgentsResponse -Agents @(
                    (New-MockAgent -Id '000' -Name 'wazuh.manager' -Status 'disconnected'),
                    (New-MockAgent -Id '001' -Name 'UBUNTU-SERVER' -Status 'active'),
                    (New-MockAgent -Id '002' -Name 'WIN11-CLIENT01' -Status 'active'),
                    (New-MockAgent -Id '003' -Name 'DC01' -Status 'active')
                )
            }

            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $result.Status | Should -Be 'Healthy'
            $result.Agents.Count | Should -Be 3
        }
    }

    Context 'Classification: Unknown' {

        It 'reports Unknown when authentication fails' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/security/user/authenticate'
            } -MockWith {
                throw [System.Net.WebException]::new('Response status code does not indicate success: 401 (Unauthorized).')
            }

            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $result.Status | Should -Be 'Unknown'
            $result.Agents.Count | Should -Be 0
            $result.Message | Should -Not -BeNullOrEmpty

            # A failed authentication means the agents endpoint is never
            # queried at all.
            Should -Invoke Invoke-RestMethod -Times 0 -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/agents'
            }
        }

        It 'reports Unknown when the agents query itself fails' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/agents'
            } -MockWith {
                throw [System.Net.WebException]::new('Unable to connect to the remote server.')
            }

            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $result.Status | Should -Be 'Unknown'
            $result.Agents.Count | Should -Be 0
            $result.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter defaults and pass-through' {

        It 'authenticates against the default base URI and checks the default three agents when no parameters are supplied' {
            Get-LabWazuhAgentStatus -Credential $script:TestCredential | Out-Null

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/security/user/authenticate"
            }

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/agents"
            }
        }

        It 'checks an explicitly supplied -AgentName list instead of the default three' {
            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName @('DC01')

            $result.Agents.Count | Should -Be 1
            $result.Agents[0].AgentName | Should -Be 'DC01'
        }
    }

    Context 'Credential and token hygiene' {

        It 'never places the JWT token or the credential on the returned object' {
            $result = Get-LabWazuhAgentStatus -Credential $script:TestCredential -AgentName $script:DefaultAgentNames

            $serialized = $result | ConvertTo-Json -Depth 5

            $serialized | Should -Not -Match ([regex]::Escape($script:TestToken))
            $result.PSObject.Properties.Name | Should -Not -Contain 'Credential'
            $result.PSObject.Properties.Name | Should -Not -Contain 'Token'
        }

        It 'never writes the JWT token or the credential to standalone console output' {
            $output = & $script:ScriptPath -Credential $script:TestCredential -AgentName $script:DefaultAgentNames |
                Out-String

            $output | Should -Not -Match ([regex]::Escape($script:TestToken))
        }
    }

    Context '-ExportPath CSV branch' {

        It 'writes one row per agent to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\wazuh-agent-status.csv'

            & $script:ScriptPath -Credential $script:TestCredential -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 3
            $csv[0].CheckName | Should -Be 'WazuhAgentStatus'
            $csv[0].BaseUri | Should -Be $script:TestBaseUri
            $csv[0].OverallStatus | Should -Be 'Healthy'
            ($csv | Where-Object { $_.AgentName -eq 'DC01' }).AgentStatus | Should -Be 'active'
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\unused.csv'

            & $script:ScriptPath -Credential $script:TestCredential | Out-Null

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
