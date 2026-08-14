<#
.SYNOPSIS
    Pester unit tests for Get-LabOUReport.ps1, using mocked Active Directory cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 03 (Static Analysis and Unit
    Testing), Step Four. Mocks the Active Directory cmdlet surface Get-LabOUReport.ps1
    calls (Get-ADOrganizationalUnit, Get-ADUser, Get-ADComputer), so the suite runs
    without a live domain and cannot read real OU data.

    New ground beyond Step Three: Get-LabOUReport.ps1 is read-only, so unlike the Lab 01
    scripts there is no write cmdlet whose invocation to assert. Instead, "read-only" is
    tested directly: a representative sample of the write cmdlets used elsewhere in this
    script library (New-ADUser, Set-ADUser, Add-ADGroupMember,
    Remove-ADPrincipalGroupMembership, Disable-ADAccount) is mocked and asserted at
    -Times 0, so the assertion actually proves something rather than checking cmdlets the
    script obviously has no reason to call.

    Get-LabOUReport.ps1 never returns its $report variable to the caller; it only pipes
    it to Format-Table and, conditionally, Export-Csv. Report content (the zero-count
    case, the -SearchScope OneLevel counts) is therefore asserted by always supplying
    -ExportPath in the relevant tests and reading the resulting CSV back from TestDrive:,
    rather than trying to capture console-formatted pipeline output the script does not
    return.

    A PowerShell single-object collection gotcha surfaced against WIN11-CLIENT01 the
    first time this suite ran: when Import-Csv reads back a file with exactly one data
    row, Windows PowerShell 5.1 assigns that single PSCustomObject directly to the
    variable rather than wrapping it in a one-element array, so .Count silently returns
    $null instead of 1. This is a property of Import-Csv's result, not a defect in
    Get-LabOUReport.ps1 (the CSV it wrote was correct); every Import-Csv read-back below
    is wrapped in @(...) to force it to stay an array regardless of row count.

    Get-ADUser's and Get-ADComputer's -SearchBase and -SearchScope parameters are plain
    string/enum-typed on the real cmdlets, not identity-typed the way Get-ADUser
    -Identity is in New-LabUser.Tests.ps1 and Add-LabGroupMembers.Tests.ps1, so
    ParameterFilter checks below compare $PesterBoundParameters['SearchBase'] and
    ['SearchScope'] directly, without the "$(...)" ToString wrapping those identity
    parameters need.

    Scope: these tests assert Get-LabOUReport.ps1's decision logic: that it performs no
    Active Directory writes, that it counts with -SearchScope OneLevel rather than the
    cmdlet default of Subtree, the zero-count case, and the -ExportPath CSV branch. As
    with the other suites in this lab, they do not assert Format-Table's console output.

    Run with:
        Invoke-Pester -Path .\Get-LabOUReport.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabOUReport.ps1'
}

Describe 'Get-LabOUReport.ps1' {

    BeforeEach {
        # A representative sample of the Active Directory write cmdlets used elsewhere
        # in this script library, registered so the 'no writes' assertions below have a
        # mock to check per Should -Invoke's requirements, and so a defect that
        # unexpectedly called one of them would be caught here instead of reaching a
        # live domain.
        Mock -CommandName New-ADUser -MockWith {}
        Mock -CommandName Set-ADUser -MockWith {}
        Mock -CommandName Add-ADGroupMember -MockWith {}
        Mock -CommandName Remove-ADPrincipalGroupMembership -MockWith {}
        Mock -CommandName Disable-ADAccount -MockWith {}
    }

    Context 'Read-only behavior' {

        BeforeEach {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'User Accounts'; DistinguishedName = 'OU=User Accounts,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-ADUser -MockWith { @() }
            Mock -CommandName Get-ADComputer -MockWith { @() }
        }

        It 'does not call any Active Directory write cmdlet' {
            & $script:ScriptPath

            Should -Invoke New-ADUser -Times 0
            Should -Invoke Set-ADUser -Times 0
            Should -Invoke Add-ADGroupMember -Times 0
            Should -Invoke Remove-ADPrincipalGroupMembership -Times 0
            Should -Invoke Disable-ADAccount -Times 0
        }

        It 'queries organizational units, users, and computers, each with a Get- cmdlet' {
            & $script:ScriptPath

            Should -Invoke Get-ADOrganizationalUnit -Times 1
            Should -Invoke Get-ADUser -Times 1
            Should -Invoke Get-ADComputer -Times 1
        }
    }

    Context 'SearchScope OneLevel' {

        BeforeEach {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'User Accounts'; DistinguishedName = 'OU=User Accounts,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-ADUser -MockWith { @() }
            Mock -CommandName Get-ADComputer -MockWith { @() }
        }

        It 'counts users with -SearchScope OneLevel rather than the cmdlet default of Subtree' {
            & $script:ScriptPath

            Should -Invoke Get-ADUser -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['SearchScope'] -eq 'OneLevel' -and
                $PesterBoundParameters['SearchBase'] -eq 'OU=User Accounts,DC=corp,DC=home,DC=arpa'
            }
        }

        It 'counts computers with -SearchScope OneLevel rather than the cmdlet default of Subtree' {
            & $script:ScriptPath

            Should -Invoke Get-ADComputer -Times 1 -Exactly -ParameterFilter {
                $PesterBoundParameters['SearchScope'] -eq 'OneLevel' -and
                $PesterBoundParameters['SearchBase'] -eq 'OU=User Accounts,DC=corp,DC=home,DC=arpa'
            }
        }
    }

    Context 'Zero-count case' {

        It 'reports zero users and zero computers for an OU with no objects' {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'Empty OU'; DistinguishedName = 'OU=Empty OU,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-ADUser -MockWith { @() }
            Mock -CommandName Get-ADComputer -MockWith { @() }

            $exportPath = 'TestDrive:\zero-count.csv'

            { & $script:ScriptPath -ExportPath $exportPath } | Should -Not -Throw

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 1
            $csv[0].Name | Should -Be 'Empty OU'
            $csv[0].UserCount | Should -Be '0'
            $csv[0].ComputerCount | Should -Be '0'
        }
    }

    Context '-ExportPath CSV branch' {

        BeforeEach {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @(
                    [PSCustomObject]@{ Name = 'User Accounts'; DistinguishedName = 'OU=User Accounts,DC=corp,DC=home,DC=arpa' }
                    [PSCustomObject]@{ Name = 'Groups'; DistinguishedName = 'OU=Groups,DC=corp,DC=home,DC=arpa' }
                )
            }
            Mock -CommandName Get-ADUser -ParameterFilter { $PesterBoundParameters['SearchBase'] -eq 'OU=User Accounts,DC=corp,DC=home,DC=arpa' } -MockWith { @(1, 2, 3) }
            Mock -CommandName Get-ADUser -ParameterFilter { $PesterBoundParameters['SearchBase'] -eq 'OU=Groups,DC=corp,DC=home,DC=arpa' } -MockWith { @() }
            Mock -CommandName Get-ADComputer -MockWith { @() }
        }

        It 'writes the report to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\ou-report.csv'

            & $script:ScriptPath -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 2
            ($csv | Where-Object Name -eq 'User Accounts').UserCount | Should -Be '3'
            ($csv | Where-Object Name -eq 'Groups').UserCount | Should -Be '0'
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\unused.csv'

            & $script:ScriptPath

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
