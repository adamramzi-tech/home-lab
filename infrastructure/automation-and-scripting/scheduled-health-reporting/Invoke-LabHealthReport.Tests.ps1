<#
.SYNOPSIS
    Pester unit tests for Invoke-LabHealthReport.ps1, mocking the three
    check functions by name.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Five. Invoke-LabHealthReport.ps1 has no REST or
    Get-Service call of its own to mock directly; per Design Decision 6,
    this suite mocks one level up, the three check functions themselves
    (Get-LabADServiceHealth, Get-LabWazuhAgentStatus,
    Get-LabDockerServiceStatus), which is only possible because
    Invoke-LabHealthReport.ps1 dot-sources the three check scripts at its
    own top level, unconditionally, rather than inside the
    Invoke-LabHealthReport function body.

    BeforeEach dot-sources Invoke-LabHealthReport.ps1 fresh for every test.
    That single dot-source call is what defines Invoke-LabHealthReport
    itself and, as a side effect, the three check functions, because
    Invoke-LabHealthReport.ps1's own top-level code dot-sources the three
    check scripts unconditionally. Mock calls placed after that dot-source
    replace the three now-real check functions for the rest of that test,
    and Invoke-LabHealthReport resolves them by name at call time, which is
    what makes this mocking approach work at all. Had the three check
    scripts instead been dot-sourced inside Invoke-LabHealthReport's own
    function body, every call would redefine the real functions over the
    top of any active Mock, and the aggregation would not be testable this
    way.

    A related testability boundary, documented in Invoke-LabHealthReport.ps1
    itself: this suite never invokes the script directly with the call
    operator (`& $script:ScriptPath`) the way the three check scripts' own
    test suites do for their console-output-hygiene assertions. Doing so
    here would re-execute the three top-level dot-source statements inside
    that run's own local scope, redefining the three check functions as
    their real, network-calling selves and shadowing any Mock set by this
    suite. Console-table rendering is therefore tested by calling
    Get-LabHealthReportSummaryTable directly against a $result this suite
    already obtained from an already-mocked Invoke-LabHealthReport call,
    never by running the file itself.

    The aggregation Context below is data-driven, built with It -ForEach
    over all twenty-seven combinations of the three checks' three possible
    states (Healthy, Unhealthy, Unknown), asserting the worst-wins rule
    from Design Decision 4 on every combination.

    Per Lab 03's own finding (PSAvoidUsingConvertToSecureStringWithPlainText),
    the test credentials built below are constructed directly from an
    empty [System.Security.SecureString]::new(), never from
    ConvertTo-SecureString with a plaintext string, since no test depends
    on either credential's actual contents. Every direct invocation of
    Invoke-LabHealthReport below supplies both credentials and
    -ReportDirectory explicitly, so no Get-Credential or Read-Host prompt
    can hang the suite. TestDrive:\ is used for -ReportDirectory
    throughout.

    Run with:
        Invoke-Pester -Path .\Invoke-LabHealthReport.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Invoke-LabHealthReport.ps1'

    # Built without ConvertTo-SecureString -AsPlainText, per Lab 03's
    # PSAvoidUsingConvertToSecureStringWithPlainText finding: an empty
    # SecureString is sufficient, since no test below depends on either
    # credential's actual contents, only on the credential object's
    # presence and its UserName for the hygiene assertions.
    $script:TestWazuhCredential = [PSCredential]::new('wazuh-wui', [System.Security.SecureString]::new())
    $script:TestPortainerCredential = [PSCredential]::new('portainer-admin', [System.Security.SecureString]::new())
    $script:TestToken = 'fake-jwt-token-value'

    function script:New-MockADResult {
        param ([Parameter(Mandatory = $false)][string]$Status = 'Healthy')

        [PSCustomObject]@{
            CheckName    = 'ADServiceHealth'
            ComputerName = 'DC01'
            Services     = @([PSCustomObject]@{ ServiceName = 'NTDS'; Status = 'Running' })
            Status       = $Status
            Message      = if ($Status -eq 'Unknown') { 'Simulated AD check failure' } else { $null }
        }
    }

    function script:New-MockWazuhResult {
        param ([Parameter(Mandatory = $false)][string]$Status = 'Healthy')

        [PSCustomObject]@{
            CheckName = 'WazuhAgentStatus'
            BaseUri   = 'https://192.168.1.226:55000'
            Agents    = @([PSCustomObject]@{ AgentName = 'DC01'; Status = 'active' })
            Status    = $Status
            Message   = if ($Status -eq 'Unknown') { 'Simulated Wazuh check failure' } else { $null }
        }
    }

    function script:New-MockDockerResult {
        param ([Parameter(Mandatory = $false)][string]$Status = 'Healthy')

        [PSCustomObject]@{
            CheckName  = 'DockerServiceStatus'
            BaseUri    = 'http://portainer.local'
            EndpointId = 3
            Containers = @([PSCustomObject]@{ ContainerName = 'portainer'; State = 'running' })
            Status     = $Status
            Message    = if ($Status -eq 'Unknown') { 'Simulated Docker check failure' } else { $null }
        }
    }
}

Describe 'Invoke-LabHealthReport.ps1' {

    BeforeEach {
        # Dot-source fresh for every test: defines Invoke-LabHealthReport,
        # ConvertTo-LabHealthReportHtml, and Get-LabHealthReportSummaryTable, and,
        # as a side effect of this file's own top-level dot-sourcing, the
        # three real check functions, so Mock below replaces the real
        # functions rather than something undefined.
        . $script:ScriptPath

        # Default mocks: all three checks Healthy, overridden per It block
        # below where the scenario under test needs a different state.
        Mock -CommandName Get-LabADServiceHealth -MockWith { New-MockADResult -Status 'Healthy' }
        Mock -CommandName Get-LabWazuhAgentStatus -MockWith { New-MockWazuhResult -Status 'Healthy' }
        Mock -CommandName Get-LabDockerServiceStatus -MockWith { New-MockDockerResult -Status 'Healthy' }
    }

    Context 'Dot-sourcing behavior' {

        It 'defines Invoke-LabHealthReport without invoking any check' {
            Get-Command -Name Invoke-LabHealthReport -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty

            Should -Invoke Get-LabADServiceHealth -Times 0
            Should -Invoke Get-LabWazuhAgentStatus -Times 0
            Should -Invoke Get-LabDockerServiceStatus -Times 0
        }

        It 'also defines the three dot-sourced check functions as a side effect, with no side effects of their own' {
            Get-Command -Name Get-LabADServiceHealth -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command -Name Get-LabWazuhAgentStatus -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command -Name Get-LabDockerServiceStatus -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }

    Context 'Read-only / call-count behavior' {

        It 'calls each of the three check functions exactly once per run' {
            $reportDir = 'TestDrive:\reports'

            Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir |
                Out-Null

            Should -Invoke Get-LabADServiceHealth -Times 1 -Exactly
            Should -Invoke Get-LabWazuhAgentStatus -Times 1 -Exactly
            Should -Invoke Get-LabDockerServiceStatus -Times 1 -Exactly
        }

        It 'passes -WazuhCredential through to Get-LabWazuhAgentStatus and -PortainerCredential through to Get-LabDockerServiceStatus' {
            $reportDir = 'TestDrive:\reports'

            Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir |
                Out-Null

            Should -Invoke Get-LabWazuhAgentStatus -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Credential'].UserName -eq $script:TestWazuhCredential.UserName
            }

            Should -Invoke Get-LabDockerServiceStatus -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Credential'].UserName -eq $script:TestPortainerCredential.UserName
            }
        }
    }

    Context 'Aggregation: worst-wins across every check-state combination' {

        # Built as plain script code directly in the Context body, not
        # inside a BeforeAll, because Pester's -ForEach needs its data at
        # Discovery time. Describe/Context bodies run during Discovery, so
        # this foreach runs then and the resulting array is available when
        # -ForEach below is evaluated; a BeforeAll block only runs later,
        # during the Run phase, which is too late for -ForEach and was
        # confirmed, by an operator's real Invoke-Pester run against an
        # earlier version of this file that built the same data inside a
        # BeforeAll, to silently produce zero tests for this Context rather
        # than an error, since -ForEach over an empty/undefined collection
        # generates no It blocks at all.
        #
        # Each combination is a Hashtable, not a PSCustomObject. Pester's
        # -ForEach only projects an item's members into named variables
        # (and into <Name> placeholders in the It title) when the item is
        # an IDictionary; a PSCustomObject is passed through as a single
        # unnamed $_ instead, with no per-property binding. An earlier
        # version of this Context used [PSCustomObject] here, and an
        # operator's real Invoke-Pester run confirmed the failure mode
        # directly: all 27 cases ran (so the loop itself executed), but
        # every title rendered with blank <AD>/<Wazuh>/<Docker>/<Expected>
        # placeholders and every assertion failed with "Expected $null,
        # but got 'Healthy'", since $AD, $Wazuh, $Docker, and $Expected
        # were never bound inside the It block at all.
        $states = @('Healthy', 'Unhealthy', 'Unknown')

        $combinations = foreach ($ad in $states) {
            foreach ($wazuh in $states) {
                foreach ($docker in $states) {
                    $expected = if (@($ad, $wazuh, $docker) -contains 'Unhealthy') {
                        'Unhealthy'
                    }
                    elseif (@($ad, $wazuh, $docker) -contains 'Unknown') {
                        'Unknown'
                    }
                    else {
                        'Healthy'
                    }

                    @{
                        AD       = $ad
                        Wazuh    = $wazuh
                        Docker   = $docker
                        Expected = $expected
                    }
                }
            }
        }

        It 'AD=<AD> Wazuh=<Wazuh> Docker=<Docker> aggregates to Overall=<Expected>' -ForEach $combinations {
            Mock -CommandName Get-LabADServiceHealth -MockWith { New-MockADResult -Status $AD }
            Mock -CommandName Get-LabWazuhAgentStatus -MockWith { New-MockWazuhResult -Status $Wazuh }
            Mock -CommandName Get-LabDockerServiceStatus -MockWith { New-MockDockerResult -Status $Docker }

            $reportDir = 'TestDrive:\reports'

            $result = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            $result.OverallStatus | Should -Be $Expected
        }
    }

    Context 'Report file behavior' {

        It 'writes a timestamped HTML report to -ReportDirectory on every run' {
            $reportDir = 'TestDrive:\reports'

            $result = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            Test-Path -Path $result.ReportPath | Should -BeTrue
            $result.ReportPath | Should -BeLike "$reportDir\LabHealthReport-*.html"
        }

        It 'creates -ReportDirectory if it does not already exist' {
            $reportDir = 'TestDrive:\does-not-exist-yet'

            Test-Path -Path $reportDir | Should -BeFalse

            Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir |
                Out-Null

            Test-Path -Path $reportDir | Should -BeTrue
        }

        It 'includes the overall status and all three check names in the report file' {
            $reportDir = 'TestDrive:\reports'

            Mock -CommandName Get-LabDockerServiceStatus -MockWith { New-MockDockerResult -Status 'Unhealthy' }

            $result = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            $content = Get-Content -Path $result.ReportPath -Raw

            $content | Should -Match 'Unhealthy'
            $content | Should -Match 'ADServiceHealth'
            $content | Should -Match 'WazuhAgentStatus'
            $content | Should -Match 'DockerServiceStatus'
        }

        It 'writes a distinct report file on each of two successive runs' {
            $reportDir = 'TestDrive:\reports'

            $first = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir
            Start-Sleep -Seconds 1
            $second = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            $first.ReportPath | Should -Not -Be $second.ReportPath
        }
    }

    Context 'Credential and token hygiene' {

        It 'never places either credential or a token on the returned object' {
            $reportDir = 'TestDrive:\reports'

            $result = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            $serialized = $result | ConvertTo-Json -Depth 6

            $serialized | Should -Not -Match ([regex]::Escape($script:TestToken))
            $serialized | Should -Not -Match 'PSCredential'
        }

        It 'never writes either credential''s username or a token into the report file' {
            $reportDir = 'TestDrive:\reports'

            $result = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            $content = Get-Content -Path $result.ReportPath -Raw

            $content | Should -Not -Match ([regex]::Escape($script:TestToken))
            $content | Should -Not -Match ([regex]::Escape($script:TestWazuhCredential.UserName))
            $content | Should -Not -Match ([regex]::Escape($script:TestPortainerCredential.UserName))
        }

        It 'never writes either credential''s username or a token to the rendered console summary table' {
            $reportDir = 'TestDrive:\reports'

            $result = Invoke-LabHealthReport -WazuhCredential $script:TestWazuhCredential -PortainerCredential $script:TestPortainerCredential -ReportDirectory $reportDir

            $output = Get-LabHealthReportSummaryTable -Result $result | Format-Table -AutoSize | Out-String

            $output | Should -Not -Match ([regex]::Escape($script:TestToken))
            $output | Should -Not -Match ([regex]::Escape($script:TestWazuhCredential.UserName))
            $output | Should -Not -Match ([regex]::Escape($script:TestPortainerCredential.UserName))
        }
    }
}
