<#
.SYNOPSIS
    Pester unit tests for Register-LabHealthReportTask.ps1, mocking the two
    state-touching ScheduledTasks cmdlets it calls.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Six-B. Extends this lab's Design Decision 6 mocking
    pattern to the ScheduledTasks module for the first time: Get-ScheduledTask
    (read) and Register-ScheduledTask (write), the two cmdlets that actually
    touch Task Scheduler state, are mocked below, so this suite registers
    nothing on the machine it runs on, per ADR-017. New-ScheduledTaskAction,
    New-ScheduledTaskTrigger, and New-ScheduledTaskSettingsSet are
    deliberately left unmocked, for a reason explained next.

    Register-LabHealthReportTask.ps1 is this track's first state-changing
    script, so this suite covers ground none of the earlier four scripts'
    tests needed to: that ShouldProcess is actually wired, not merely
    declared (the -WhatIf Context calls Register-ScheduledTask zero times,
    which is the real assertion; a passing suite that only checked the
    attribute exists would not catch a ShouldProcess block that never
    gates anything), and that a second run against an already-registered
    task name fails loudly rather than falling through to
    Register-ScheduledTask's own less specific behavior.

    New-ScheduledTaskAction, New-ScheduledTaskTrigger, and
    New-ScheduledTaskSettingsSet are deliberately not mocked, which is
    itself a real finding rather than an oversight: a first real run of
    this suite mocked all three to return plain PSCustomObjects, and every
    test that reached the mocked Register-ScheduledTask call failed with
    ParameterBindingArgumentTransformationException, "Cannot convert the
    ... value of type System.Management.Automation.PSCustomObject to type
    Microsoft.Management.Infrastructure.CimInstance[]". Pester's Mock
    reuses the real cmdlet's own parameter metadata when it builds a mocked
    command's proxy, so Register-ScheduledTask's genuinely CimInstance-typed
    -Action and -Trigger parameters still reject a same-shaped-but-wrong-type
    fake object even though the command itself is mocked; the type check
    happens during parameter binding, before the mock body or any
    ParameterFilter ever runs. The three builder cmdlets are, unlike
    Get-ScheduledTask and Register-ScheduledTask, purely local: they
    construct an in-memory CIM instance describing an action, trigger, or
    settings set and touch no Task Scheduler state on the machine they run
    on, so calling the real cmdlets here does not compromise this suite's
    "nothing is registered during a test run" requirement, and it is what
    lets a genuinely typed CimInstance reach the mocked Register-ScheduledTask
    call without the conversion failing. The Argument/Trigger/Settings
    Contexts below therefore assert against the real returned CimInstance
    objects' own properties (.Execute, .Arguments, .StartBoundary,
    .StartWhenAvailable, .ExecutionTimeLimit) as seen by
    Register-ScheduledTask's ParameterFilter, not against a mock's inputs.
    Per the confirmed Get-Help Register-ScheduledTask -Full output this
    script's own .DESCRIPTION cites, -Action and -Trigger are both
    CimInstance[] (array-typed, hence the [0] indexing below) while
    -Settings is a single CimInstance, not an array.

    A third real finding shaped the Trigger tests specifically: a live
    check, (New-ScheduledTaskTrigger -Daily -At '07:00').StartBoundary,
    returned '2026-08-19T11:00:00Z' on WIN11-CLIENT01, an ISO 8601 string
    in UTC with a trailing Z, not a local-time string, and not the
    'T07:00:00' local-time substring an earlier version of this suite
    assumed and got wrong (that version's two Trigger tests failed with
    "was called 0 times" against an otherwise-passing suite, since
    Register-ScheduledTask genuinely was being called correctly and only
    the assumed match string was wrong). Hardcoding the UTC offset this
    machine happened to show (UTC-4, EDT) would make the test fragile
    against DST and against running on a differently-configured machine, so
    the fix parses StartBoundary back with [datetimeoffset] and compares
    its .LocalDateTime against the requested time, which is self-consistent
    on whatever machine actually runs the suite rather than pinned to one
    observed offset.

    A meaningful limit on what this suite can prove is stated here rather
    than left implicit. Register-ScheduledTask has no -LogonType parameter
    of its own; LogonType Password is Microsoft's documented, undocumented-
    in-this-Get-Help-output side effect of supplying -User and -Password
    together, per this script's own .DESCRIPTION and the Get-Help
    Register-ScheduledTask -Full output checked live before this script
    was written. Mocking Register-ScheduledTask can assert this script
    calls it with -User, -Password, and -RunLevel Limited, and never with
    -Principal, but it cannot assert what LogonType the real cmdlet
    actually assigns the registered task, since that happens inside
    Register-ScheduledTask's own implementation, not in anything this
    script's mocked call can observe. Per this lab's own recurring finding
    that a passing suite does not prove live behavior (Step Four's
    array-nesting defect, Step Six-A's empty-response guard), that
    question is answered live in Step Six-B's own Implementation, with
    Get-ScheduledTask -TaskName <name> | Select-Object -ExpandProperty
    Principal against the actually-registered task, not by this suite.

    $script:TestRunAsCredential's password is a second real finding, and a
    deliberate departure from this lab's usual empty-SecureString practice
    (Lab 03's PSAvoidUsingConvertToSecureStringWithPlainText finding). Every
    earlier credential in this lab is built from an empty
    [System.Security.SecureString]::new(), because none of those scripts
    ever decomposes the credential into a raw string of its own; Wazuh and
    Portainer both take the whole [PSCredential] and hand it to
    Invoke-RestMethod's own -Credential parameter. This script is the
    first to unwrap a credential's password into a bare [string] at a call
    site, for Register-ScheduledTask's -Password parameter, and a first
    real run of this suite with the usual empty SecureString failed every
    test that reached the mocked Register-ScheduledTask call with
    ParameterBindingValidationException: "Cannot validate argument on
    parameter 'Password'. The argument is null or empty." Register-ScheduledTask's
    real -Password parameter carries its own non-empty validation, and,
    consistent with the -Action type-binding finding above, Pester's Mock
    enforces it too. The fix keeps clear of ConvertTo-SecureString
    -AsPlainText, and so of PSAvoidUsingConvertToSecureStringWithPlainText,
    by building the SecureString character by character with
    [SecureString]::AppendChar() instead, giving this suite a genuinely
    non-empty, still never-plaintext-cmdlet-constructed password. Its
    value, 'HygieneCheckOnly123!', is deliberately distinctive so the
    Credential hygiene Context below can assert on more than an empty
    string.

    $PesterBoundParameters is used for every ParameterFilter below, per
    this lab's stated testing standard.

    Run with:
        Invoke-Pester -Path .\Register-LabHealthReportTask.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Register-LabHealthReportTask.ps1'

    # Built with AppendChar, not ConvertTo-SecureString -AsPlainText: see
    # this file's own .DESCRIPTION for why an empty SecureString, this
    # lab's usual test-credential practice, is not viable here.
    $script:TestRunAsPassword = [System.Security.SecureString]::new()
    foreach ($char in 'HygieneCheckOnly123!'.ToCharArray()) {
        $script:TestRunAsPassword.AppendChar($char)
    }
    $script:TestRunAsCredential = [PSCredential]::new('CORP\labadmin', $script:TestRunAsPassword)

    function script:New-MockScheduledTask {
        param (
            [Parameter(Mandatory = $false)]
            [string]$TaskName = 'LabHealthReport',

            [Parameter(Mandatory = $false)]
            [string]$TaskPath = '\',

            [Parameter(Mandatory = $false)]
            [string]$State = 'Ready'
        )

        [PSCustomObject]@{
            TaskName = $TaskName
            TaskPath = $TaskPath
            State    = $State
        }
    }
}

Describe 'Register-LabHealthReportTask.ps1' {

    BeforeEach {
        # Default: no task by that name already registered, overridden in
        # the 'Already-exists behavior' Context below.
        Mock -CommandName Get-ScheduledTask -MockWith { $null }

        # New-ScheduledTaskAction, New-ScheduledTaskTrigger, and
        # New-ScheduledTaskSettingsSet are deliberately left unmocked; see
        # this file's own .DESCRIPTION for the real Pester failure that
        # this design resolved.
        Mock -CommandName Register-ScheduledTask -MockWith { New-MockScheduledTask }

        # A representative sample of other state-changing ScheduledTasks
        # cmdlets this script has no reason to call, registered so an
        # unexpected call would be caught here instead of reaching a live
        # host.
        Mock -CommandName Unregister-ScheduledTask -MockWith {}
        Mock -CommandName Set-ScheduledTask -MockWith {}
        Mock -CommandName Disable-ScheduledTask -MockWith {}

        # Dot-source fresh for every test, so each test's
        # Register-LabHealthReportTask function reflects the current file
        # and no state leaks between tests.
        . $script:ScriptPath
    }

    Context 'Dot-sourcing behavior' {

        It 'defines the Register-LabHealthReportTask function without registering anything' {
            Get-Command -Name Register-LabHealthReportTask -CommandType Function -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty

            Should -Invoke Register-ScheduledTask -Times 0
            Should -Invoke Get-ScheduledTask -Times 0
        }
    }

    Context 'Argument string construction' {

        It 'builds the exact command line Step Six-A validated, using default parameters' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Action'][0].Execute -eq 'powershell.exe' -and
                $PesterBoundParameters['Action'][0].Arguments -eq '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\Scripts\Invoke-LabHealthReport.ps1 -SecretsDirectory C:\Secrets -ReportDirectory C:\Reports'
            }
        }

        It 'reflects overridden -ScriptPath, -SecretsDirectory, and -ReportDirectory in the built argument string' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential -ScriptPath 'D:\Scripts\Invoke-LabHealthReport.ps1' `
                -SecretsDirectory 'D:\Secrets' -ReportDirectory 'D:\Reports' | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Action'][0].Arguments -eq '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File D:\Scripts\Invoke-LabHealthReport.ps1 -SecretsDirectory D:\Secrets -ReportDirectory D:\Reports'
            }
        }
    }

    Context 'Trigger and settings match Design Decision 5' {

        It 'builds a daily trigger at the default 07:00 local time' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                ([datetimeoffset]$PesterBoundParameters['Trigger'][0].StartBoundary).LocalDateTime.ToString('HH:mm:ss') -eq '07:00:00'
            }
        }

        It 'builds a daily trigger at an overridden -TriggerTime' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential -TriggerTime '22:30' | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                ([datetimeoffset]$PesterBoundParameters['Trigger'][0].StartBoundary).LocalDateTime.ToString('HH:mm:ss') -eq '22:30:00'
            }
        }

        It 'builds settings with -StartWhenAvailable and the default 15-minute -ExecutionTimeLimit' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Settings'].StartWhenAvailable -eq $true -and
                "$($PesterBoundParameters['Settings'].ExecutionTimeLimit)" -eq 'PT15M'
            }
        }

        It 'applies an overridden -ExecutionTimeLimitMinutes to the settings' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential -ExecutionTimeLimitMinutes 30 | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['Settings'].ExecutionTimeLimit)" -eq 'PT30M'
            }
        }
    }

    Context 'Registration: -User/-Password/-RunLevel, not -Principal' {

        It 'calls Register-ScheduledTask exactly once with -User, -Password, and -RunLevel Limited, never -Principal' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['User'] -eq $script:TestRunAsCredential.UserName -and
                "$($PesterBoundParameters['Password'])" -eq $script:TestRunAsCredential.GetNetworkCredential().Password -and
                "$($PesterBoundParameters['RunLevel'])" -eq 'Limited' -and
                -not $PesterBoundParameters.ContainsKey('Principal')
            }
        }

        It 'passes the default -TaskName and -TaskPath through to Register-ScheduledTask' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['TaskName'] -eq 'LabHealthReport' -and
                $PesterBoundParameters['TaskPath'] -eq '\'
            }
        }
    }

    Context 'ShouldProcess / -WhatIf' {

        It 'calls Register-ScheduledTask zero times under -WhatIf' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential -WhatIf | Out-Null

            Should -Invoke Register-ScheduledTask -Times 0
        }

        It 'still runs the already-exists precondition check under -WhatIf' {
            Mock -CommandName Get-ScheduledTask -MockWith { New-MockScheduledTask }

            { Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential -WhatIf } |
                Should -Throw '*already exists*'

            Should -Invoke Register-ScheduledTask -Times 0
        }
    }

    Context 'Already-exists behavior' {

        BeforeEach {
            Mock -CommandName Get-ScheduledTask -MockWith { New-MockScheduledTask }
        }

        It 'throws without registering when the task already exists and -Force is not supplied' {
            { Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential } |
                Should -Throw '*already exists*'

            Should -Invoke Register-ScheduledTask -Times 0
        }

        It 'proceeds and calls Register-ScheduledTask once when -Force is supplied against an existing task' {
            Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential -Force | Out-Null

            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['Force'] -eq $true
            }
        }
    }

    Context 'Credential hygiene' {

        It 'never places the run-as credential, its username, or its password on the returned object' {
            $result = Register-LabHealthReportTask -RunAsCredential $script:TestRunAsCredential

            $serialized = $result | ConvertTo-Json -Depth 6

            $serialized | Should -Not -Match 'PSCredential'
            $serialized | Should -Not -Match 'SecureString'
            $serialized | Should -Not -Match ([regex]::Escape($script:TestRunAsCredential.UserName))
            $serialized | Should -Not -Match ([regex]::Escape('HygieneCheckOnly123!'))
        }

        It 'never writes the run-as credential''s username or password to the rendered console summary when run standalone' {
            $output = & $script:ScriptPath -RunAsCredential $script:TestRunAsCredential | Out-String

            $output | Should -Not -Match ([regex]::Escape($script:TestRunAsCredential.UserName))
            $output | Should -Not -Match ([regex]::Escape('HygieneCheckOnly123!'))
            $output | Should -Not -Match 'PSCredential'
            $output | Should -Not -Match 'SecureString'
        }
    }
}
