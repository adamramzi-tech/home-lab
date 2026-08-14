<#
.SYNOPSIS
    Pester unit tests for Get-LabAccountInventory.ps1, using mocked Active Directory
    cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 03 (Static Analysis and Unit
    Testing), Step Four. Mocks the Active Directory cmdlet surface
    Get-LabAccountInventory.ps1 calls (Get-ADUser, Get-ADPrincipalGroupMembership), so
    the suite runs without a live domain and cannot read real account data.

    Unlike Remove-LabUser.Tests.ps1 (Step Three), the group objects
    Get-ADPrincipalGroupMembership returns here are never passed as an argument to
    another typed Active Directory cmdlet; they only flow through this script's own
    Where-Object filter and Select-Object -ExpandProperty Name, both of which read
    properties directly off the object rather than through parameter binding. That
    sidesteps the ADPrincipal-typed -MemberOf binding gotcha Remove-LabUser.Tests.ps1
    documents: a plain PSCustomObject with DistinguishedName and Name properties is
    enough here, with no cast to a real ADPrincipal type needed.

    Get-LabAccountInventory.ps1 never returns its $report variable to the caller either;
    it only pipes it to Format-Table and, conditionally, Export-Csv. As with
    Get-LabOUReport.Tests.ps1, report content (primary-group exclusion, LastLogonDate
    preservation) is asserted by always supplying -ExportPath in these tests and reading
    the resulting CSV back from TestDrive:.

    The same PowerShell single-object collection gotcha documented in
    Get-LabOUReport.Tests.ps1 applies here: Import-Csv reading back a one-row CSV
    returns a scalar PSCustomObject in Windows PowerShell 5.1, not a one-element array,
    so .Count on it silently returns $null. Every Import-Csv read-back below is wrapped
    in @(...) for that reason.

    Scope: these tests assert Get-LabAccountInventory.ps1's decision logic: that it
    performs no Active Directory writes, that the Groups field excludes the account's
    primary group while including its other memberships, and that a blank
    LastLogonDate is preserved as $null rather than substituted with a placeholder. As
    with the other suites in this lab, they do not assert Format-Table's console
    output.

    Run with:
        Invoke-Pester -Path .\Get-LabAccountInventory.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Get-LabAccountInventory.ps1'

    # A single reusable mocked account, shared by every Context below except where a
    # test needs to vary one field (LastLogonDate) deliberately. Returned as a
    # one-element array since Get-ADUser -Filter * returns a collection.
    function script:New-MockADUserRecord {
        param (
            [Parameter(Mandatory = $false)] $LastLogonDate = (Get-Date '2025-06-01')
        )

        [PSCustomObject]@{
            SamAccountName    = 'tuser01'
            Name              = 'Test User'
            Enabled           = $true
            DistinguishedName = 'CN=Test User,OU=User Accounts,DC=corp,DC=home,DC=arpa'
            whenCreated       = Get-Date '2025-01-01'
            PasswordLastSet   = Get-Date '2025-01-01'
            LastLogonDate     = $LastLogonDate
            PrimaryGroup      = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa'
        }
    }
}

Describe 'Get-LabAccountInventory.ps1' {

    BeforeEach {
        # A representative sample of the Active Directory write cmdlets used elsewhere
        # in this script library, registered so the 'no writes' assertion below has a
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
            Mock -CommandName Get-ADUser -MockWith { @(New-MockADUserRecord) }
            Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
                @([PSCustomObject]@{ Name = 'Domain Users'; DistinguishedName = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa' })
            }
        }

        It 'does not call any Active Directory write cmdlet' {
            & $script:ScriptPath

            Should -Invoke New-ADUser -Times 0
            Should -Invoke Set-ADUser -Times 0
            Should -Invoke Add-ADGroupMember -Times 0
            Should -Invoke Remove-ADPrincipalGroupMembership -Times 0
            Should -Invoke Disable-ADAccount -Times 0
        }

        It 'queries accounts and group memberships, each with a Get- cmdlet' {
            & $script:ScriptPath

            Should -Invoke Get-ADUser -Times 1
            Should -Invoke Get-ADPrincipalGroupMembership -Times 1
        }
    }

    Context 'Primary-group exclusion' {

        BeforeEach {
            Mock -CommandName Get-ADUser -MockWith { @(New-MockADUserRecord) }
            Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
                @(
                    [PSCustomObject]@{ Name = 'Domain Users'; DistinguishedName = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa' }
                    [PSCustomObject]@{ Name = 'IT-Admins'; DistinguishedName = 'CN=IT-Admins,OU=Groups,DC=corp,DC=home,DC=arpa' }
                    [PSCustomObject]@{ Name = 'Linux-Admins'; DistinguishedName = 'CN=Linux-Admins,OU=Groups,DC=corp,DC=home,DC=arpa' }
                )
            }
        }

        It 'excludes the primary group from the Groups field but includes the other memberships' {
            $exportPath = 'TestDrive:\inventory-primary-group.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv.Count | Should -Be 1
            $csv[0].Groups | Should -Not -Match 'Domain Users'
            $csv[0].Groups | Should -Match 'IT-Admins'
            $csv[0].Groups | Should -Match 'Linux-Admins'
        }
    }

    Context 'LastLogonDate preservation' {

        It 'leaves LastLogonDate blank rather than substituting a placeholder when Active Directory returns no value' {
            Mock -CommandName Get-ADUser -MockWith { @(New-MockADUserRecord -LastLogonDate $null) }
            Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
                @([PSCustomObject]@{ Name = 'Domain Users'; DistinguishedName = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa' })
            }

            $exportPath = 'TestDrive:\inventory-blank-logon.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv[0].LastLogonDate | Should -BeNullOrEmpty
        }

        It 'reports the actual LastLogonDate value when Active Directory returns one' {
            Mock -CommandName Get-ADUser -MockWith { @(New-MockADUserRecord -LastLogonDate (Get-Date '2025-06-01T08:00:00')) }
            Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
                @([PSCustomObject]@{ Name = 'Domain Users'; DistinguishedName = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa' })
            }

            $exportPath = 'TestDrive:\inventory-with-logon.csv'

            & $script:ScriptPath -ExportPath $exportPath

            $csv = @(Import-Csv -Path $exportPath)
            $csv[0].LastLogonDate | Should -Not -BeNullOrEmpty
        }
    }

    Context '-ExportPath CSV branch' {

        BeforeEach {
            Mock -CommandName Get-ADUser -MockWith { @(New-MockADUserRecord) }
            Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
                @([PSCustomObject]@{ Name = 'Domain Users'; DistinguishedName = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa' })
            }
        }

        It 'writes the report to the path supplied via -ExportPath' {
            $exportPath = 'TestDrive:\inventory-export.csv'

            & $script:ScriptPath -ExportPath $exportPath

            Test-Path -Path $exportPath | Should -BeTrue

            $csv = @(Import-Csv -Path $exportPath)
            $csv[0].SamAccountName | Should -Be 'tuser01'
        }

        It 'does not write a CSV when -ExportPath is not supplied' {
            $exportPath = 'TestDrive:\inventory-unused.csv'

            & $script:ScriptPath

            Test-Path -Path $exportPath | Should -BeFalse
        }
    }
}
