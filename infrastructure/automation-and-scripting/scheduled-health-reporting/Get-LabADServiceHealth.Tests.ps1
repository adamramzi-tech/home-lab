<#
.SYNOPSIS
    Pester unit tests for Get-LabADServiceHealth.ps1, using a mocked
    Get-Service.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Two. Mocks Get-Service, the only external command
    Get-LabADServiceHealth.ps1 calls, so the suite runs without contacting
    DC01, extending Lab 03's mocking pattern to a non-Active-Directory
    cmdlet for the first time in this track, per this lab's Design
    Decision 6.

    Get-LabADServiceHealth.ps1 is the first script in this lab to use the
    dot-sourced-function invocation model from Design Decision 2: the
    script file, dot-sourced, must define the Get-LabADServiceHealth
    function with no side effects (no query against DC01, no console
    output), and only running the file directly is expected to invoke the
    function and render its result. The BeforeEach block below dot-sources
    the script before every test, both to make the function available to
    call directly for the classification tests and to give the dedicated
    'Dot-sourcing behavior' Context a way to assert that the dot-source
    itself calls Get-Service zero times.

    Because Get-LabADServiceHealth (the function) returns its
    PSCustomObject result directly, rather than only piping it to
    Format-Table the way the Lab 04 reporting scripts do, the classification
    tests below call the function directly after dot-sourcing and assert on
    its returned Status, Services, and Message properties, per this lab's
    Design Decision 6 ("each individual check script's own tests will
    assert its classification mapping directly"), rather than round-tripping
    through a CSV export the way Get-LabGPOInventory.Tests.ps1 has to for a
    script whose report variable is never returned. The -ExportPath CSV
    branch itself is only reachable through the standalone (non-dot-sourced)
    path, so that Context invokes the script file directly with
    & $script:ScriptPath and reads the resulting CSV back from TestDrive:,
    wrapped in @(...) per the single-row Import-Csv collection behavior
    documented in Lab 03.

    Get-Service's -ComputerName parameter is a plain string on the real
    cmdlet, not Active-Directory-object-typed, so unlike Get-ADUser -Identity
    or Get-GPInheritance -Target elsewhere in this track, no ToString
    coercion workaround is needed to compare its bound value. The script
    calls Get-Service without -Name, enumerating every service on the target
    with -ErrorAction Stop and matching the requested names against the
    returned collection itself, per the error-handling design settled by
    live diagnostic in Get-LabADServiceHealth.ps1 (see this lab's Step Two
    Troubleshooting). The pass-through Context below therefore asserts that
    -ComputerName is bound, that -ErrorAction is Stop, and that -Name is not
    bound at all, rather than asserting a -Name value; the explicit-override
    test additionally asserts that the requested -ServiceName is applied by
    the script's own filtering of the returned collection rather than passed
    to Get-Service. $PesterBoundParameters is used for every ParameterFilter
    and Should -Invoke -ParameterFilter below, per this lab's stated testing
    standard.

    PSScriptAnalyzer's PSAvoidUsingComputerNameHardcoded rule flags a
    literal string passed directly to a -ComputerName parameter at a call
    site (it does not flag a -ComputerName parameter's own default value in
    a param block, which is why Get-LabADServiceHealth.ps1 itself is clean).
    The fixture target names below are held in $script:TargetComputerName
    and $script:AlternateComputerName and passed as variables at every call
    site instead, which clears the rule without suppressing it or changing
    what each test actually exercises.

    Run with:
        Invoke-Pester -Path .\Get-LabADServiceHealth.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabADServiceHealth.ps1'
    $script:DefaultServiceNames = @('NTDS', 'DNS', 'Netlogon', 'Kdc', 'W32Time', 'ADWS')
    $script:TargetComputerName = 'DC01'
    $script:AlternateComputerName = 'DC02'

    # A reusable mocked service record, shared by every Context below.
    function script:New-MockService {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Name,

            [Parameter(Mandatory = $false)]
            [string]$Status = 'Running'
        )

        [PSCustomObject]@{
            Name   = $Name
            Status = $Status
        }
    }
}

Describe 'Get-LabADServiceHealth.ps1' {

    BeforeEach {
        # A representative sample of state-changing service cmdlets this
        # script has no reason to call, registered so the 'no writes'
        # assertion below has a mock to check per Should -Invoke's
        # requirements, and so a defect that unexpectedly called one of them
        # would be caught here instead of reaching a live host.
        Mock -CommandName Set-Service -MockWith {}
        Mock -CommandName Stop-Service -MockWith {}
        Mock -CommandName Start-Service -MockWith {}
        Mock -CommandName Restart-Service -MockWith {}

        # A default no-op Get-Service mock, overridden per Context below
        # where the classification under test needs specific data.
        Mock -CommandName Get-Service -MockWith { @() }

        # Dot-source the script fresh for every test, so each test's
        # Get-LabADServiceHealth function reflects the current file and no
        # state leaks between tests.
        . $script:ScriptPath
    }

    Context 'Dot-sourcing behavior' {

        It 'defines the Get-LabADServiceHealth function without invoking a check' {
            Get-Command -Name Get-LabADServiceHealth -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty

            Should -Invoke Get-Service -Times 0
        }
    }

    Context 'Read-only behavior' {

        It 'does not call any state-changing service cmdlet' {
            & $script:ScriptPath | Out-Null

            Should -Invoke Set-Service -Times 0
            Should -Invoke Stop-Service -Times 0
            Should -Invoke Start-Service -Times 0
            Should -Invoke Restart-Service -Times 0
        }
    }

    Context 'Classification: Healthy' {

        It 'reports Healthy when every named service is Running' {
            Mock -CommandName Get-Service -MockWith {
                @(
                    (New-MockService -Name 'NTDS'),
                    (New-MockService -Name 'DNS'),
                    (New-MockService -Name 'Netlogon'),
                    (New-MockService -Name 'Kdc'),
                    (New-MockService -Name 'W32Time'),
                    (New-MockService -Name 'ADWS')
                )
            }

            $result = Get-LabADServiceHealth -ComputerName $script:TargetComputerName -ServiceName $script:DefaultServiceNames

            $result.Status | Should -Be 'Healthy'
            $result.Services.Count | Should -Be 6
            ($result.Services | Where-Object { $_.Status -ne 'Running' }) | Should -BeNullOrEmpty
        }
    }

    Context 'Classification: Unhealthy' {

        It 'reports Unhealthy when the query completes but a named service is not Running' {
            Mock -CommandName Get-Service -MockWith {
                @(
                    (New-MockService -Name 'NTDS' -Status 'Stopped'),
                    (New-MockService -Name 'DNS'),
                    (New-MockService -Name 'Netlogon'),
                    (New-MockService -Name 'Kdc'),
                    (New-MockService -Name 'W32Time'),
                    (New-MockService -Name 'ADWS')
                )
            }

            $result = Get-LabADServiceHealth -ComputerName $script:TargetComputerName -ServiceName $script:DefaultServiceNames

            $result.Status | Should -Be 'Unhealthy'
            ($result.Services | Where-Object { $_.ServiceName -eq 'NTDS' }).Status | Should -Be 'Stopped'
        }

        It 'reports Unhealthy when a named service is not found on the target' {
            Mock -CommandName Get-Service -MockWith {
                # 'Kdc' deliberately absent, simulating Get-Service not
                # finding that service name on the target computer.
                @(
                    (New-MockService -Name 'NTDS'),
                    (New-MockService -Name 'DNS'),
                    (New-MockService -Name 'Netlogon'),
                    (New-MockService -Name 'W32Time'),
                    (New-MockService -Name 'ADWS')
                )
            }

            $result = Get-LabADServiceHealth -ComputerName $script:TargetComputerName -ServiceName $script:DefaultServiceNames

            $result.Status | Should -Be 'Unhealthy'
            ($result.Services | Where-Object { $_.ServiceName -eq 'Kdc' }).Status | Should -Be 'NotFound'
        }
    }

    Context 'Classification: Unknown' {

        # The real cmdlet does not raise a terminating error here on its own.
        # Verified live in Step Two: against an unreachable target,
        # Get-Service -ComputerName (enumerating without -Name) reports that
        # it cannot open the Service Control Manager, and that error is
        # terminating only because the script passes -ErrorAction Stop; the
        # script's original -Name / -ErrorAction SilentlyContinue form
        # suppressed the equivalent failure and it never reached the catch,
        # which is the defect this test now guards against. The mock
        # therefore emits the Service-Control-Manager failure with
        # Write-Error (a non-terminating error) rather than a bare throw, so
        # its terminating-ness depends on the -ErrorAction Stop the script
        # passes: this test classifies Unknown only while the script keeps
        # -ErrorAction Stop, and would fail (the error swallowed, the check
        # falling through to Unhealthy) if the script reverted to suppressing
        # errors, instead of passing on a broken production path the way an
        # unconditional throw would.
        It 'reports Unknown when the query itself fails' {
            Mock -CommandName Get-Service -MockWith {
                Write-Error -Exception ([System.InvalidOperationException]::new(
                        "Cannot open Service Control Manager on computer 'DC01'. This operation might require other privileges."))
            }

            $result = Get-LabADServiceHealth -ComputerName $script:TargetComputerName -ServiceName $script:DefaultServiceNames

            $result.Status | Should -Be 'Unknown'
            $result.Services.Count | Should -Be 0
            $result.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter defaults and pass-through' {

        It 'queries the default target with -ErrorAction Stop and no -Name filter when no parameters are supplied' {
            Get-LabADServiceHealth | Out-Null

            Should -Invoke Get-Service -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['ComputerName'] -eq $script:TargetComputerName -and
                $PesterBoundParameters['ErrorAction'] -eq 'Stop' -and
                -not $PesterBoundParameters.ContainsKey('Name')
            }
        }

        It 'passes an explicitly supplied -ComputerName through to Get-Service and applies -ServiceName by filtering the returned set' {
            Mock -CommandName Get-Service -MockWith {
                @(
                    (New-MockService -Name 'NTDS'),
                    (New-MockService -Name 'DNS'),
                    (New-MockService -Name 'Netlogon'),
                    (New-MockService -Name 'Kdc'),
                    (New-MockService -Name 'W32Time'),
                    (New-MockService -Name 'ADWS'),
                    (New-MockService -Name 'Spooler'),
                    (New-MockService -Name 'BITS')
                )
            }

            $result = Get-LabADServiceHealth -ComputerName $script:AlternateComputerName -ServiceName @('NTDS', 'DNS')

            Should -Invoke Get-Service -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['ComputerName'] -eq $script:AlternateComputerName -and
                $PesterBoundParameters['ErrorAction'] -eq 'Stop' -and
                -not $PesterBoundParameters.ContainsKey('Name')
            }

            # -ServiceName is not passed to Get-Service; the script filters
            # the enumerated collection down to the requested names itself, so
            # only the two requested services appear on the result even though
            # the mock returned eight.
            $result.Services.Count | Should -Be 2
            ($result.Services.ServiceName | Sort-Object) | Should -Be @('DNS', 'NTDS')
            $result.Status | Should -Be 'Healthy'
        }
    }

    Context '-ExportPath CSV branch' {

        BeforeEach {
            Mock -CommandName Get-Service -MockWith {
                @(
                    (New-MockService -Name 'NTDS'),
                    (New-MockService -Name 'DNS'),
                    (New-MockService -Name 'Netlogon'),
                    (New-MockService -Name 'Kdc'),
                    (New-MockService -Name 'W32Time'),
                    (New-MockService -Name 'ADWS')
                )
            }
        }

        It 'writes one row per service to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\ad-service-health.csv'

            & $script:ScriptPath -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 6
            $csv[0].CheckName | Should -Be 'ADServiceHealth'
            $csv[0].ComputerName | Should -Be 'DC01'
            $csv[0].OverallStatus | Should -Be 'Healthy'
            ($csv | Where-Object { $_.ServiceName -eq 'Kdc' }).ServiceStatus | Should -Be 'Running'
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\unused.csv'

            & $script:ScriptPath | Out-Null

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
