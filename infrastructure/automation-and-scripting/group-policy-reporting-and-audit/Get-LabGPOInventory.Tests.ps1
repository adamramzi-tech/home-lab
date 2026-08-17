<#
.SYNOPSIS
    Pester unit tests for Get-LabGPOInventory.ps1, using mocked Group Policy
    cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 04 (Group Policy
    Reporting and Audit), Step Two. Mocks the Group Policy cmdlet surface
    Get-LabGPOInventory.ps1 calls (Get-GPO), so the suite runs without a
    live domain and cannot read real GPO data.

    Get-LabGPOInventory.ps1 is the first script in this track authored under
    the Lab 03 testing standard from the outset rather than retrofitted, but
    its Pester coverage follows the same shape Lab 03 established for the
    Lab 02 reporting scripts: this script is read-only, so unlike Lab 01's
    write scripts there is no write cmdlet of its own to assert an
    invocation against. Instead, "read-only" is tested directly against a
    representative sample of the Group Policy write cmdlets this library
    could use elsewhere (New-GPO, New-GPLink, Set-GPLink, Set-GPInheritance,
    Set-GPPermission), each mocked and asserted at -Times 0, matching the
    read-only assertion pattern Get-LabOUReport.Tests.ps1 and
    Get-LabAccountInventory.Tests.ps1 used against the Active Directory write
    cmdlet surface.

    Get-LabGPOInventory.ps1 never returns its $report variable to the
    caller; it only pipes it to Format-Table and, conditionally,
    Export-Csv. As with the Lab 02 reporting suites, report content
    (DisplayName sort order, the exact field set) is asserted by always
    supplying -ExportPath in the relevant tests and reading the resulting
    CSV back from TestDrive:, rather than trying to capture console-formatted
    pipeline output the script does not return.

    Get-GPO's -All switch and the objects it returns are not passed as an
    argument to any other typed Group Policy cmdlet in this script, so
    unlike Get-GPInheritance -Target or Get-GPResultantSetOfPolicy -User in
    the other two Lab 04 scripts, there is no AD-object-typed parameter here
    needing the "$($PesterBoundParameters['X'])" ToString comparison
    documented elsewhere in this lab's test files; a plain PSCustomObject
    mock with DisplayName, Id, GpoStatus, CreationTime, and
    ModificationTime properties is enough, read directly off the object
    rather than through parameter binding.

    The same single-row Import-Csv collection gotcha documented in
    Get-LabOUReport.Tests.ps1 (Lab 03) applies here: Windows PowerShell 5.1's
    Import-Csv returns a scalar PSCustomObject, not a one-element array, for
    a file with exactly one data row, so .Count on it silently returns $null.
    Every Import-Csv read-back below is wrapped in @(...) for that reason.

    Scope: these tests assert Get-LabGPOInventory.ps1's decision logic: that
    it performs no Group Policy writes, that it sorts by DisplayName rather
    than trusting Get-GPO -All's return order, that the reported field set
    matches the plan (DisplayName, Id, GpoStatus, CreationTime,
    ModificationTime), and the -ExportPath CSV branch. As with the other
    suites in this track, they do not assert Format-Table's console output.

    Run with:
        Invoke-Pester -Path .\Get-LabGPOInventory.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabGPOInventory.ps1'

    # A reusable mocked GPO record, shared by every Context below except
    # where a test needs to vary DisplayName or GpoStatus deliberately.
    function script:New-MockGPO {
        param (
            [Parameter(Mandatory = $true)]
            [string]$DisplayName,

            [Parameter(Mandatory = $false)]
            [string]$GpoStatus = 'AllSettingsEnabled',

            [Parameter(Mandatory = $false)]
            [datetime]$CreationTime = (Get-Date '2026-06-04'),

            [Parameter(Mandatory = $false)]
            [datetime]$ModificationTime = (Get-Date '2026-06-04')
        )

        [PSCustomObject]@{
            DisplayName      = $DisplayName
            Id               = [Guid]::NewGuid()
            GpoStatus        = $GpoStatus
            CreationTime     = $CreationTime
            ModificationTime = $ModificationTime
        }
    }
}

Describe 'Get-LabGPOInventory.ps1' {

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
            Mock -CommandName Get-GPO -MockWith {
                @(New-MockGPO -DisplayName 'Default Domain Policy')
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

        It 'queries GPOs with a Get- cmdlet' {
            & $script:ScriptPath

            Should -Invoke Get-GPO -Times 1
        }
    }

    Context 'DisplayName sort order' {

        It 'sorts the report by DisplayName rather than trusting Get-GPO -All''s return order' {
            Mock -CommandName Get-GPO -MockWith {
                @(
                    (New-MockGPO -DisplayName 'Workstation-Security-Baseline')
                    (New-MockGPO -DisplayName 'Default Domain Policy')
                    (New-MockGPO -DisplayName 'Standard-User-Environment')
                    (New-MockGPO -DisplayName 'IT-Admin-Environment')
                    (New-MockGPO -DisplayName 'Default Domain Controllers Policy')
                )
            }

            $exportPath = 'TestDrive:\gpo-sort-order.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 5
            $csv[0].DisplayName | Should -Be 'Default Domain Controllers Policy'
            $csv[1].DisplayName | Should -Be 'Default Domain Policy'
            $csv[2].DisplayName | Should -Be 'IT-Admin-Environment'
            $csv[3].DisplayName | Should -Be 'Standard-User-Environment'
            $csv[4].DisplayName | Should -Be 'Workstation-Security-Baseline'
        }
    }

    Context 'Reported field set' {

        It 'reports DisplayName, Id, GpoStatus, CreationTime, and ModificationTime for each GPO' {
            Mock -CommandName Get-GPO -MockWith {
                @(New-MockGPO -DisplayName 'Workstation-Security-Baseline' -GpoStatus 'UserSettingsDisabled')
            }

            $exportPath = 'TestDrive:\gpo-fields.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 1
            $csv[0].DisplayName | Should -Be 'Workstation-Security-Baseline'
            $csv[0].GpoStatus | Should -Be 'UserSettingsDisabled'
            $csv[0].Id | Should -Not -BeNullOrEmpty
            $csv[0].CreationTime | Should -Not -BeNullOrEmpty
            $csv[0].ModificationTime | Should -Not -BeNullOrEmpty
        }
    }

    Context '-ExportPath CSV branch' {

        BeforeEach {
            Mock -CommandName Get-GPO -MockWith {
                @(
                    (New-MockGPO -DisplayName 'Default Domain Policy')
                    (New-MockGPO -DisplayName 'IT-Admin-Environment')
                )
            }
        }

        It 'writes the report to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\gpo-inventory.csv'

            & $script:ScriptPath -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 2
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\unused.csv'

            & $script:ScriptPath

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
