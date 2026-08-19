<#
.SYNOPSIS
    Pester unit tests for Get-LabDockerServiceStatus.ps1, using a mocked
    Invoke-RestMethod.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Four. Mocks Invoke-RestMethod, the only external
    command Get-LabDockerServiceStatus.ps1 calls, so the suite runs without
    contacting the Portainer API, extending Design Decision 6's mocking
    pattern to this lab's third and final Invoke-RestMethod-based check.

    Get-LabDockerServiceStatus.ps1 copies the dot-sourced-function
    invocation model Get-LabADServiceHealth.ps1 (Step Two) and
    Get-LabWazuhAgentStatus.ps1 (Step Three) established: the script file,
    dot-sourced, must define the Get-LabDockerServiceStatus function with no
    side effects (no call against the Portainer API, no console output), and
    only running the file directly is expected to invoke the function and
    render its result. The BeforeEach block below dot-sources the script
    before every test, both to make the function available to call directly
    for the classification tests and to give the dedicated 'Dot-sourcing
    behavior' Context a way to assert that the dot-source itself calls
    Invoke-RestMethod zero times.

    Because Get-LabDockerServiceStatus (the function) returns its
    PSCustomObject result directly, the classification tests below call the
    function directly after dot-sourcing and assert on its returned Status,
    Containers, and Message properties, the same pattern the two earlier
    check scripts' suites used, rather than round-tripping through a CSV
    export.

    Invoke-RestMethod is called twice by a successful run: once to
    authenticate (POST .../api/auth) and once to list containers
    (GET .../docker/containers/json?all=true). The two calls are
    distinguished in every ParameterFilter below by matching against the
    -Uri each call uses, since both calls are made against the same mocked
    command name. $PesterBoundParameters is used for every ParameterFilter
    and Should -Invoke -ParameterFilter below, per this lab's stated testing
    standard. Every direct & $script:ScriptPath invocation below passes
    -Credential explicitly, so the standalone Get-Credential prompt cannot
    hang the run.

    Per Lab 03's own finding (PSAvoidUsingConvertToSecureStringWithPlainText,
    resolved in that lab by replacing a plaintext ConvertTo-SecureString
    call with an empty [System.Security.SecureString]::new()), the test
    credential built below never calls ConvertTo-SecureString with a
    plaintext string; it constructs a PSCredential directly from an empty
    SecureString, since none of the tests below depend on the password's
    actual contents.

    The default mocked container set below (New-DefaultMockContainerSet) is
    the curated eight-container expected-running baseline, all reporting a
    running state, used as the default healthy scenario most Contexts start
    from and override where the scenario under test needs different data.
    A separate scenario, in the 'Real-environment baseline' Context, mirrors
    Implementation Step One's exact ten-container live finding: the Wazuh
    stack, nginx-proxy-manager, and portainer running, prometheus, grafana,
    and node-exporter exited, and the docker-networking project's frontend
    and backend containers present and exited but outside the expected list
    entirely.

    Run with:
        Invoke-Pester -Path .\Get-LabDockerServiceStatus.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabDockerServiceStatus.ps1'
    $script:TestBaseUri = 'http://portainer.local'
    $script:TestEndpointId = 3
    $script:TestToken = 'fake-jwt-token-value'
    $script:DefaultExpectedContainers = @(
        'single-node-wazuh.manager-1',
        'single-node-wazuh.indexer-1',
        'single-node-wazuh.dashboard-1',
        'nginx-proxy-manager',
        'portainer',
        'prometheus',
        'grafana',
        'node-exporter'
    )

    # Built without ConvertTo-SecureString -AsPlainText, per Lab 03's
    # PSAvoidUsingConvertToSecureStringWithPlainText finding: an empty
    # SecureString is sufficient, since no test below depends on the
    # password's actual contents.
    $script:TestCredential = [PSCredential]::new('admin', [System.Security.SecureString]::new())

    # A reusable mocked Docker container record, shaped the way Portainer's
    # containers endpoint actually returns one: Names as a leading-slash
    # array, plus Image and Status fields the script itself never reads.
    function script:New-MockContainer {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Name,

            [Parameter(Mandatory = $false)]
            [string]$State = 'running',

            [Parameter(Mandatory = $false)]
            [string]$Image = 'some/image:latest',

            [Parameter(Mandatory = $false)]
            [string]$Status = 'Up 7 days'
        )

        [PSCustomObject]@{
            Names  = @("/$Name")
            Image  = $Image
            State  = $State
            Status = $Status
        }
    }

    # The curated eight-container expected-running baseline, all running:
    # the default healthy scenario most Contexts below start from.
    function script:New-DefaultMockContainerSet {
        @(
            (New-MockContainer -Name 'single-node-wazuh.manager-1' -State 'running'),
            (New-MockContainer -Name 'single-node-wazuh.indexer-1' -State 'running'),
            (New-MockContainer -Name 'single-node-wazuh.dashboard-1' -State 'running'),
            (New-MockContainer -Name 'nginx-proxy-manager' -State 'running'),
            (New-MockContainer -Name 'portainer' -State 'running'),
            (New-MockContainer -Name 'prometheus' -State 'running'),
            (New-MockContainer -Name 'grafana' -State 'running'),
            (New-MockContainer -Name 'node-exporter' -State 'running')
        )
    }

    function script:New-MockAuthResponse {
        [PSCustomObject]@{ jwt = $script:TestToken }
    }
}

Describe 'Get-LabDockerServiceStatus.ps1' {

    BeforeEach {
        # Default mocks: a successful authentication and a healthy
        # eight-container response (the curated expected set, all running),
        # overridden per It block below where the scenario under test needs
        # different data. Distinguished by -Uri, since both calls share the
        # same mocked command name.
        Mock -CommandName Invoke-RestMethod -ParameterFilter {
            $PesterBoundParameters['Uri'] -like '*/api/auth'
        } -MockWith { New-MockAuthResponse }

        Mock -CommandName Invoke-RestMethod -ParameterFilter {
            $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
        } -MockWith { New-DefaultMockContainerSet }

        # Dot-source the script fresh for every test, so each test's
        # Get-LabDockerServiceStatus function reflects the current file and
        # no state leaks between tests.
        . $script:ScriptPath
    }

    Context 'Dot-sourcing behavior' {

        It 'defines the Get-LabDockerServiceStatus function without invoking a check' {
            Get-Command -Name Get-LabDockerServiceStatus -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty

            Should -Invoke Invoke-RestMethod -Times 0
        }
    }

    Context 'Read-only behavior' {

        It 'calls Invoke-RestMethod only for the auth POST and the containers GET, nothing else' {
            Get-LabDockerServiceStatus -Credential $script:TestCredential | Out-Null

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Method'] -eq 'Post' -and
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/api/auth"
            }

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Method'] -eq 'Get' -and
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/api/endpoints/$script:TestEndpointId/docker/containers/json?all=true"
            }

            # No other call, of any method or against any other URI, was made.
            Should -Invoke Invoke-RestMethod -Times 2 -Exactly
        }
    }

    Context 'Classification: Healthy' {

        It 'reports Healthy when every expected container is present and running' {
            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Healthy'
            $result.Containers.Count | Should -Be 8
            ($result.Containers | Where-Object { $_.State -ne 'running' }) | Should -BeNullOrEmpty
        }
    }

    Context 'Response deserialization (single-pipeline-object array)' {

        It 'classifies correctly when the containers endpoint emits its whole array as one pipeline object' {
            # The unary comma operator forces this mock to write the entire
            # array to the pipeline as a single object, the same way the
            # real Invoke-RestMethod call against this endpoint's top-level
            # JSON array response does: one object emitted, that object
            # being the whole array, rather than one object emitted per
            # container. The default mocks elsewhere in this file do not
            # reproduce this shape, since Pester's own MockWith return
            # unrolls a returned array onto the pipeline element by
            # element, unlike the real cmdlet, which is exactly what let
            # the nested-array defect this test guards against (documented
            # in this step's Troubleshooting) pass every other test in this
            # file while still failing live.
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            } -MockWith {
                , (New-DefaultMockContainerSet)
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Healthy'
            $result.Containers.Count | Should -Be 8
            ($result.Containers | Where-Object { $_.State -ne 'running' }) | Should -BeNullOrEmpty
            ($result.Containers | Where-Object { $_.State -is [array] }) | Should -BeNullOrEmpty
        }
    }

    Context 'Classification: Unhealthy' {

        It 'reports Unhealthy, with the real state, when an expected container is present but not running' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            } -MockWith {
                @(
                    (New-MockContainer -Name 'single-node-wazuh.manager-1' -State 'running'),
                    (New-MockContainer -Name 'single-node-wazuh.indexer-1' -State 'running'),
                    (New-MockContainer -Name 'single-node-wazuh.dashboard-1' -State 'running'),
                    (New-MockContainer -Name 'nginx-proxy-manager' -State 'running'),
                    (New-MockContainer -Name 'portainer' -State 'running'),
                    (New-MockContainer -Name 'prometheus' -State 'running'),
                    (New-MockContainer -Name 'grafana' -State 'running'),
                    (New-MockContainer -Name 'node-exporter' -State 'exited')
                )
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Unhealthy'
            ($result.Containers | Where-Object { $_.ContainerName -eq 'node-exporter' }).State | Should -Be 'exited'
        }

        It 'reports Unhealthy, NotFound, when an expected container is missing from the response entirely' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            } -MockWith {
                # grafana deliberately absent, simulating a container removed
                # or never created on the target endpoint.
                @(
                    (New-MockContainer -Name 'single-node-wazuh.manager-1' -State 'running'),
                    (New-MockContainer -Name 'single-node-wazuh.indexer-1' -State 'running'),
                    (New-MockContainer -Name 'single-node-wazuh.dashboard-1' -State 'running'),
                    (New-MockContainer -Name 'nginx-proxy-manager' -State 'running'),
                    (New-MockContainer -Name 'portainer' -State 'running'),
                    (New-MockContainer -Name 'prometheus' -State 'running'),
                    (New-MockContainer -Name 'node-exporter' -State 'running')
                )
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Unhealthy'
            ($result.Containers | Where-Object { $_.ContainerName -eq 'grafana' }).State | Should -Be 'NotFound'
        }

        It 'ignores the docker-networking teaching containers (frontend, backend) even when present and exited' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            } -MockWith {
                # frontend and backend are present and exited, exactly like
                # Step One's live baseline, but neither is in the expected
                # list, so neither should be able to influence the result.
                @(New-DefaultMockContainerSet) + @(
                    (New-MockContainer -Name 'frontend' -State 'exited'),
                    (New-MockContainer -Name 'backend' -State 'exited')
                )
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Healthy'
            $result.Containers.Count | Should -Be 8
            ($result.Containers | Where-Object { $_.ContainerName -in @('frontend', 'backend') }) | Should -BeNullOrEmpty
        }
    }

    Context 'Real-environment baseline (Implementation Step One)' {

        It 'reports Unhealthy, driven only by the monitoring stack, against Step One''s exact ten-container live finding' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            } -MockWith {
                @(
                    (New-MockContainer -Name 'single-node-wazuh.dashboard-1' -State 'running'),
                    (New-MockContainer -Name 'single-node-wazuh.manager-1' -State 'running'),
                    (New-MockContainer -Name 'single-node-wazuh.indexer-1' -State 'running'),
                    (New-MockContainer -Name 'nginx-proxy-manager' -State 'running'),
                    (New-MockContainer -Name 'portainer' -State 'running'),
                    (New-MockContainer -Name 'prometheus' -State 'exited'),
                    (New-MockContainer -Name 'grafana' -State 'exited'),
                    (New-MockContainer -Name 'node-exporter' -State 'exited'),
                    (New-MockContainer -Name 'frontend' -State 'exited'),
                    (New-MockContainer -Name 'backend' -State 'exited')
                )
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Unhealthy'
            $result.Containers.Count | Should -Be 8

            $stopped = $result.Containers | Where-Object { $_.State -ne 'running' }
            $stopped.ContainerName | Sort-Object | Should -Be @('grafana', 'node-exporter', 'prometheus')

            $running = $result.Containers | Where-Object { $_.State -eq 'running' }
            $running.ContainerName | Sort-Object | Should -Be @(
                'nginx-proxy-manager', 'portainer', 'single-node-wazuh.dashboard-1',
                'single-node-wazuh.indexer-1', 'single-node-wazuh.manager-1'
            )
        }
    }

    Context 'Classification: Unknown' {

        It 'reports Unknown when authentication fails' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/api/auth'
            } -MockWith {
                throw [System.Net.WebException]::new('Response status code does not indicate success: 401 (Unauthorized).')
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Unknown'
            $result.Containers.Count | Should -Be 0
            $result.Message | Should -Not -BeNullOrEmpty

            # A failed authentication means the containers endpoint is never
            # queried at all.
            Should -Invoke Invoke-RestMethod -Times 0 -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            }
        }

        It 'reports Unknown when the containers query itself fails' {
            Mock -CommandName Invoke-RestMethod -ParameterFilter {
                $PesterBoundParameters['Uri'] -like '*/docker/containers/json*'
            } -MockWith {
                throw [System.Net.WebException]::new('Unable to connect to the remote server.')
            }

            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $result.Status | Should -Be 'Unknown'
            $result.Containers.Count | Should -Be 0
            $result.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter defaults and pass-through' {

        It 'authenticates against the default base URI and endpoint when no parameters are supplied' {
            Get-LabDockerServiceStatus -Credential $script:TestCredential | Out-Null

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/api/auth"
            }

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/api/endpoints/$script:TestEndpointId/docker/containers/json?all=true"
            }
        }

        It 'checks an explicitly supplied -ExpectedContainer list instead of the curated default' {
            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer @('portainer')

            $result.Containers.Count | Should -Be 1
            $result.Containers[0].ContainerName | Should -Be 'portainer'
        }

        It 'queries the explicitly supplied -EndpointId instead of the default' {
            Get-LabDockerServiceStatus -Credential $script:TestCredential -EndpointId 7 | Out-Null

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Uri'] -eq "$script:TestBaseUri/api/endpoints/7/docker/containers/json?all=true"
            }
        }
    }

    Context 'Credential and token hygiene' {

        It 'never places the JWT token or the credential on the returned object' {
            $result = Get-LabDockerServiceStatus -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers

            $serialized = $result | ConvertTo-Json -Depth 5

            $serialized | Should -Not -Match ([regex]::Escape($script:TestToken))
            $result.PSObject.Properties.Name | Should -Not -Contain 'Credential'
            $result.PSObject.Properties.Name | Should -Not -Contain 'Token'
        }

        It 'never writes the JWT token or the credential to standalone console output' {
            $output = & $script:ScriptPath -Credential $script:TestCredential -ExpectedContainer $script:DefaultExpectedContainers |
                Out-String

            $output | Should -Not -Match ([regex]::Escape($script:TestToken))
        }
    }

    Context '-ExportPath CSV branch' {

        It 'writes one row per expected container to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\docker-service-status.csv'

            & $script:ScriptPath -Credential $script:TestCredential -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 8
            $csv[0].CheckName | Should -Be 'DockerServiceStatus'
            $csv[0].BaseUri | Should -Be $script:TestBaseUri
            $csv[0].OverallStatus | Should -Be 'Healthy'
            ($csv | Where-Object { $_.ContainerName -eq 'portainer' }).ContainerState | Should -Be 'running'
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\unused.csv'

            & $script:ScriptPath -Credential $script:TestCredential | Out-Null

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
