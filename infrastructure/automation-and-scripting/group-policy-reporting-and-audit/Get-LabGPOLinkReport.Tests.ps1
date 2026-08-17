<#
.SYNOPSIS
    Pester unit tests for Get-LabGPOLinkReport.ps1, using mocked Active
    Directory and Group Policy cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 04 (Group Policy
    Reporting and Audit), Step Three. Mocks the cmdlet surface
    Get-LabGPOLinkReport.ps1 calls (Get-ADOrganizationalUnit,
    Get-GPInheritance), so the suite runs without a live domain and cannot
    read real OU or Group Policy link data.

    Get-GPInheritance's -Target parameter is Active-Directory-object-typed
    on the real cmdlet, the same category of identity parameter
    Get-LabOUReport.Tests.ps1 (Lab 03) documents for Get-ADUser -SearchBase.
    Every ParameterFilter and Should -Invoke -ParameterFilter against
    -Target below compares "$($PesterBoundParameters['Target'])" (forcing
    ToString) rather than the bound value directly, per this lab's stated
    testing standard. $PesterBoundParameters is used throughout, never
    $PSBoundParameters, matching the distinction Lab 03's New-LabUser.Tests.ps1
    first established.

    Get-LabGPOLinkReport.ps1 never returns its $report variable to the
    caller; it only pipes it to Format-Table and, conditionally,
    Export-Csv. As with the other reporting suites in this track, report
    content (the directly-linked/inherited-only distinction, the
    GpoInheritanceBlocked and per-link Order/Enabled/Enforced fields, the
    empty-InheritedGpoLinks case) is asserted by always supplying
    -ExportPath in the relevant tests and reading the resulting CSV back
    from TestDrive:, rather than trying to capture the console-formatted
    Format-Table output the script does not return.

    The mocked Get-GPInheritance return value's GpoLinks and
    InheritedGpoLinks collections are built from a local New-MockGPLink
    helper, plain PSCustomObjects with DisplayName, Order, Enabled, and
    Enforced properties. The script only reads properties off these objects
    directly (a Where-Object filter and property access), it never passes
    them as an argument to another typed cmdlet, so unlike
    Remove-LabUser.Tests.ps1's ADPrincipal-typed -MemberOf binding (Lab 03),
    no cast to a real Group Policy type is needed here. GpoInheritanceBlocked
    is mocked as a boolean ($false / $true). Step One's raw console baseline
    showed this property displayed as "No", which initially read as a
    string, but Step Five's live run of Get-LabGPOLinkReport.ps1 itself
    showed the same field rendered as "False" in the script's own table and
    CSV output. The underlying property is a real boolean; "No" was
    PowerShell's default format view for the GPInheritance type dressing
    it up for direct console display, not the literal value. The script
    passes the property through unmodified either way, so this was a
    correction to this test file's mocked type and documentation, not a
    script defect.

    The same single-row Import-Csv collection gotcha documented in
    Get-LabOUReport.Tests.ps1 (Lab 03) applies here: Windows PowerShell 5.1's
    Import-Csv returns a scalar PSCustomObject, not a one-element array, for
    a file with exactly one data row, so .Count on it silently returns $null.
    Every Import-Csv read-back below is wrapped in @(...) for that reason.

    Scope: these tests assert Get-LabGPOLinkReport.ps1's decision logic:
    that it performs no Group Policy writes, that it queries
    Get-GPInheritance once per OU targeted at that OU's distinguished name,
    the directly-linked-vs-inherited-only distinction, the
    GpoInheritanceBlocked/Order/Enabled/Enforced field mapping, the
    empty-InheritedGpoLinks case, and the -ExportPath CSV branch. As with
    the other suites in this track, they do not assert Format-Table's
    console output.

    Run with:
        Invoke-Pester -Path .\Get-LabGPOLinkReport.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabGPOLinkReport.ps1'

    # A reusable mocked GPO link record, shared by every Context below.
    function script:New-MockGPLink {
        param (
            [Parameter(Mandatory = $true)]
            [string]$DisplayName,

            [Parameter(Mandatory = $false)]
            [int]$Order = 1,

            [Parameter(Mandatory = $false)]
            [bool]$Enabled = $true,

            [Parameter(Mandatory = $false)]
            [bool]$Enforced = $false
        )

        [PSCustomObject]@{
            DisplayName = $DisplayName
            Order       = $Order
            Enabled     = $Enabled
            Enforced    = $Enforced
        }
    }

    # A reusable mocked Get-GPInheritance return value.
    function script:New-MockGPInheritance {
        param (
            [Parameter(Mandatory = $false)]
            [array]$GpoLinks = @(),

            [Parameter(Mandatory = $false)]
            [array]$InheritedGpoLinks = @(),

            [Parameter(Mandatory = $false)]
            [bool]$GpoInheritanceBlocked = $false
        )

        [PSCustomObject]@{
            GpoLinks              = $GpoLinks
            InheritedGpoLinks     = $InheritedGpoLinks
            GpoInheritanceBlocked = $GpoInheritanceBlocked
        }
    }
}

Describe 'Get-LabGPOLinkReport.ps1' {

    BeforeEach {
        # A representative sample of the Group Policy write cmdlets this
        # script library could use elsewhere, registered so the 'no writes'
        # assertions below have a mock to check per Should -Invoke's
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
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'Workstations'; DistinguishedName = 'OU=Workstations,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-GPInheritance -MockWith {
                New-MockGPInheritance -GpoLinks @(New-MockGPLink -DisplayName 'Workstation-Security-Baseline') `
                    -InheritedGpoLinks @(
                    (New-MockGPLink -DisplayName 'Workstation-Security-Baseline' -Order 1)
                    (New-MockGPLink -DisplayName 'Default Domain Policy' -Order 2)
                )
            }
        }

        It 'does not call any Group Policy write cmdlet' {
            & $script:ScriptPath

            Should -Invoke New-GPO -Times 0
            Should -Invoke New-GPLink -Times 0
            Should -Invoke Set-GPLink -Times 0
            Should -Invoke Set-GPInheritance -Times 0
            Should -Invoke Set-GPPermission -Times 0
        }

        It 'queries organizational units and Group Policy inheritance, each with a Get- cmdlet' {
            & $script:ScriptPath

            Should -Invoke Get-ADOrganizationalUnit -Times 1
            Should -Invoke Get-GPInheritance -Times 1
        }
    }

    Context 'Per-OU Get-GPInheritance targeting' {

        It 'queries Get-GPInheritance once per OU, targeted at that OU''s distinguished name' {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @(
                    [PSCustomObject]@{ Name = 'IT'; DistinguishedName = 'OU=IT,DC=corp,DC=home,DC=arpa' }
                    [PSCustomObject]@{ Name = 'Workstations'; DistinguishedName = 'OU=Workstations,DC=corp,DC=home,DC=arpa' }
                )
            }
            Mock -CommandName Get-GPInheritance -ParameterFilter {
                "$($PesterBoundParameters['Target'])" -eq 'OU=IT,DC=corp,DC=home,DC=arpa'
            } -MockWith {
                New-MockGPInheritance -GpoLinks @(New-MockGPLink -DisplayName 'IT-Admin-Environment') `
                    -InheritedGpoLinks @(New-MockGPLink -DisplayName 'IT-Admin-Environment')
            }
            Mock -CommandName Get-GPInheritance -ParameterFilter {
                "$($PesterBoundParameters['Target'])" -eq 'OU=Workstations,DC=corp,DC=home,DC=arpa'
            } -MockWith {
                New-MockGPInheritance -GpoLinks @(New-MockGPLink -DisplayName 'Workstation-Security-Baseline') `
                    -InheritedGpoLinks @(New-MockGPLink -DisplayName 'Workstation-Security-Baseline')
            }

            & $script:ScriptPath

            Should -Invoke Get-GPInheritance -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['Target'])" -eq 'OU=IT,DC=corp,DC=home,DC=arpa'
            }
            Should -Invoke Get-GPInheritance -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['Target'])" -eq 'OU=Workstations,DC=corp,DC=home,DC=arpa'
            }
        }
    }

    Context 'Directly-linked vs inherited-only distinction' {

        It 'flags a GPO present in both GpoLinks and InheritedGpoLinks as directly linked, and one present only in InheritedGpoLinks as not' {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'Workstations'; DistinguishedName = 'OU=Workstations,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-GPInheritance -MockWith {
                New-MockGPInheritance -GpoLinks @(New-MockGPLink -DisplayName 'Workstation-Security-Baseline' -Order 1) `
                    -InheritedGpoLinks @(
                    (New-MockGPLink -DisplayName 'Workstation-Security-Baseline' -Order 1)
                    (New-MockGPLink -DisplayName 'Default Domain Policy' -Order 2)
                )
            }

            $exportPath = 'TestDrive:\directly-linked.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 2
            ($csv | Where-Object GpoDisplayName -eq 'Workstation-Security-Baseline').DirectlyLinked | Should -Be 'True'
            ($csv | Where-Object GpoDisplayName -eq 'Default Domain Policy').DirectlyLinked | Should -Be 'False'
        }
    }

    Context 'GpoInheritanceBlocked and per-link Order/Enabled/Enforced' {

        It 'reports GpoInheritanceBlocked and each link''s Order, Enabled, and Enforced state' {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'IT'; DistinguishedName = 'OU=IT,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-GPInheritance -MockWith {
                New-MockGPInheritance -GpoInheritanceBlocked $true `
                    -GpoLinks @(New-MockGPLink -DisplayName 'IT-Admin-Environment' -Order 1 -Enabled $true -Enforced $true) `
                    -InheritedGpoLinks @(New-MockGPLink -DisplayName 'IT-Admin-Environment' -Order 1 -Enabled $true -Enforced $true)
            }

            $exportPath = 'TestDrive:\inheritance-blocked.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 1
            $csv[0].GpoInheritanceBlocked | Should -Be 'True'
            $csv[0].LinkOrder | Should -Be '1'
            $csv[0].LinkEnabled | Should -Be 'True'
            $csv[0].LinkEnforced | Should -Be 'True'
        }
    }

    Context 'OU with no effective GPO links' {

        It 'contributes no rows for an OU with an empty InheritedGpoLinks list, without dropping other OUs'' rows' {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @(
                    [PSCustomObject]@{ Name = 'Groups'; DistinguishedName = 'OU=Groups,DC=corp,DC=home,DC=arpa' }
                    [PSCustomObject]@{ Name = 'IT'; DistinguishedName = 'OU=IT,DC=corp,DC=home,DC=arpa' }
                )
            }
            Mock -CommandName Get-GPInheritance -ParameterFilter {
                "$($PesterBoundParameters['Target'])" -eq 'OU=Groups,DC=corp,DC=home,DC=arpa'
            } -MockWith {
                New-MockGPInheritance -GpoLinks @() -InheritedGpoLinks @()
            }
            Mock -CommandName Get-GPInheritance -ParameterFilter {
                "$($PesterBoundParameters['Target'])" -eq 'OU=IT,DC=corp,DC=home,DC=arpa'
            } -MockWith {
                New-MockGPInheritance -GpoLinks @(New-MockGPLink -DisplayName 'IT-Admin-Environment') `
                    -InheritedGpoLinks @(New-MockGPLink -DisplayName 'IT-Admin-Environment')
            }

            $exportPath = 'TestDrive:\empty-ou.csv'

            { & $script:ScriptPath -ExportPath $exportPath } | Should -Not -Throw

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 1
            $csv[0].OUName | Should -Be 'IT'
        }
    }

    Context '-ExportPath CSV branch' {

        BeforeEach {
            Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                @([PSCustomObject]@{ Name = 'Workstations'; DistinguishedName = 'OU=Workstations,DC=corp,DC=home,DC=arpa' })
            }
            Mock -CommandName Get-GPInheritance -MockWith {
                New-MockGPInheritance -GpoLinks @(New-MockGPLink -DisplayName 'Workstation-Security-Baseline') `
                    -InheritedGpoLinks @(New-MockGPLink -DisplayName 'Workstation-Security-Baseline')
            }
        }

        It 'writes the report to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\gpo-link-report.csv'

            & $script:ScriptPath -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 1
            $csv[0].OUName | Should -Be 'Workstations'
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\unused.csv'

            & $script:ScriptPath

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
