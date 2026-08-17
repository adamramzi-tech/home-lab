<#
.SYNOPSIS
    Pester unit tests for Get-LabRSoPReport.ps1, using a mocked
    Get-GPResultantSetOfPolicy.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 04 (Group Policy
    Reporting and Audit), Step Four. Mocks Get-GPResultantSetOfPolicy, the
    only Group Policy cmdlet Get-LabRSoPReport.ps1 calls, so the suite runs
    without a live domain or client.

    Get-LabRSoPReport.ps1 is deliberately the exception to this lab's
    coverage standard, per the plan: it is a thin wrapper around
    Get-GPResultantSetOfPolicy's native HTML/XML report generation, with no
    console table, no -ExportPath branch, and no report content of its own
    to assert against a mock, since the cmdlet writes the report file
    directly rather than returning data this script reshapes. Its Pester
    coverage is limited to the decision logic it does have: that it makes
    no Group Policy writes, that it passes -User, -Computer, -Path, and
    -ReportType through to Get-GPResultantSetOfPolicy correctly (including
    the 'Html' default), and that it catches the cmdlet's failure rather
    than letting an unhandled exception propagate. The script's real proof
    is the live gpresult cross-check in Step Five, not this suite, per the
    plan.

    Get-GPResultantSetOfPolicy's -User and -Computer parameters are
    Active-Directory-object-typed on the real cmdlet, the same category of
    identity parameter documented in Get-LabGPOLinkReport.Tests.ps1 for
    Get-GPInheritance -Target. Every ParameterFilter and
    Should -Invoke -ParameterFilter against -User or -Computer below
    compares "$($PesterBoundParameters['X'])" (forcing ToString) rather
    than the bound value directly, per this lab's stated testing standard.
    -Path and -ReportType are plain string-typed parameters and are
    compared directly.

    None of these tests assert against the report file Get-GPResultantSetOfPolicy
    would actually write, since the cmdlet itself is mocked to a no-op; the
    live diagnostic performed during Step Four already exercised the real
    file output for both the success and failure cases this suite models.

    Run with:
        Invoke-Pester -Path .\Get-LabRSoPReport.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabRSoPReport.ps1'
}

Describe 'Get-LabRSoPReport.ps1' {

    BeforeEach {
        # A representative sample of the Group Policy write cmdlets this
        # script library could use elsewhere, registered so the 'no writes'
        # assertion below has a mock to check per Should -Invoke's
        # requirements, and so a defect that unexpectedly called one of them
        # would be caught here instead of reaching a live domain.
        Mock -CommandName New-GPO -MockWith {}
        Mock -CommandName New-GPLink -MockWith {}
        Mock -CommandName Set-GPLink -MockWith {}
        Mock -CommandName Set-GPInheritance -MockWith {}
        Mock -CommandName Set-GPPermission -MockWith {}
    }

    Context 'Read-only behavior' {

        BeforeEach {
            Mock -CommandName Get-GPResultantSetOfPolicy -MockWith {}
        }

        It 'does not call any Group Policy write cmdlet' {
            & $script:ScriptPath -User 'CORP\testuser01' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop.html'

            Should -Invoke New-GPO -Times 0
            Should -Invoke New-GPLink -Times 0
            Should -Invoke Set-GPLink -Times 0
            Should -Invoke Set-GPInheritance -Times 0
            Should -Invoke Set-GPPermission -Times 0
        }

        It 'generates the RSoP report with a Get- cmdlet' {
            & $script:ScriptPath -User 'CORP\testuser01' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop.html'

            Should -Invoke Get-GPResultantSetOfPolicy -Times 1
        }
    }

    Context 'Parameter pass-through' {

        BeforeEach {
            Mock -CommandName Get-GPResultantSetOfPolicy -MockWith {}
        }

        It 'passes -User, -Computer, and -Path through to Get-GPResultantSetOfPolicy unchanged' {
            & $script:ScriptPath -User 'CORP\testuser01' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop-passthrough.html'

            Should -Invoke Get-GPResultantSetOfPolicy -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['User'])" -eq 'CORP\testuser01' -and
                "$($PesterBoundParameters['Computer'])" -eq 'CORP\WIN11-CLIENT01' -and
                $PesterBoundParameters['Path'] -eq 'TestDrive:\rsop-passthrough.html'
            }
        }

        It 'defaults -ReportType to Html when not supplied' {
            & $script:ScriptPath -User 'CORP\testuser01' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop-default-type.html'

            Should -Invoke Get-GPResultantSetOfPolicy -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['ReportType'] -eq 'Html'
            }
        }

        It 'passes an explicitly supplied -ReportType through unchanged' {
            & $script:ScriptPath -User 'CORP\testuser01' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop-xml.xml' -ReportType Xml

            Should -Invoke Get-GPResultantSetOfPolicy -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['ReportType'] -eq 'Xml'
            }
        }
    }

    Context 'Success path' {

        It 'does not throw when Get-GPResultantSetOfPolicy succeeds' {
            Mock -CommandName Get-GPResultantSetOfPolicy -MockWith {}

            { & $script:ScriptPath -User 'CORP\labadmin' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop-success.html' } | Should -Not -Throw
        }
    }

    Context 'Failure handling' {

        It 'catches a failure from Get-GPResultantSetOfPolicy rather than letting it propagate' {
            Mock -CommandName Get-GPResultantSetOfPolicy -MockWith {
                throw [System.ArgumentException]::new('The Resultant Set of Policy (RSoP) report cannot be generated for user CORP\jsmith on the CORP\WIN11-CLIENT01 computer because there is no RSoP logging data for that user on that computer.')
            }

            { & $script:ScriptPath -User 'CORP\jsmith' -Computer 'CORP\WIN11-CLIENT01' -Path 'TestDrive:\rsop-failure.html' } | Should -Not -Throw

            Should -Invoke Get-GPResultantSetOfPolicy -Times 1
        }
    }
}
