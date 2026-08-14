<#
.SYNOPSIS
    Pester unit tests for Add-LabGroupMembers.ps1, using mocked Active Directory cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 03 (Static Analysis and Unit
    Testing), Step Four. Mocks the full Active Directory cmdlet surface
    Add-LabGroupMembers.ps1 calls (Get-ADGroup, Get-ADUser, Add-ADGroupMember,
    Get-ADGroupMember), so the suite runs without a live domain and cannot write to a
    real AD group.

    New ground beyond Step Three: this script reads its input from a CSV file rather
    than taking parameters directly, so these tests write throwaway input CSVs to
    Pester's TestDrive: (a per-run temporary location Pester cleans up automatically)
    instead of mocking Import-Csv itself. Import-Csv is a built-in cmdlet operating on
    a real file, not an Active Directory cmdlet, so it is left unmocked and simply
    reads whatever the test wrote to TestDrive:.

    Get-ADGroup's -Identity and Get-ADUser's -Identity are typed
    (ADGroup / ADUser) on the real cmdlets, the same coercion Step Three documented for
    Add-ADGroupMember's -Identity/-Members: Pester's mock proxy preserves those types,
    so a plain string this script passes is bound as a typed AD object, not a string.
    ParameterFilter and Should -Invoke -ParameterFilter checks below compare against
    "$($PesterBoundParameters['Identity'])" (forces .ToString()) for that reason,
    consistent with the pattern Step Three proved against Add-ADGroupMember and
    Remove-ADPrincipalGroupMembership. The same applies to Add-ADGroupMember's
    -Identity/-Members and Get-ADGroupMember's -Identity below.

    Scope: these tests assert Add-LabGroupMembers.ps1's decision logic: the CSV header
    validation, the group-existence pre-flight check, the per-member pre-validation
    that produces the script's partial-success batch model (an invalid member is
    excluded from a group's batch while the remaining valid members in the same batch
    still get added, since Add-ADGroupMember validates its entire -Members array
    atomically and one bad name would otherwise block every valid member in the same
    call), the grouping of CSV rows by GroupName into one Add-ADGroupMember call per
    group, and the query-back via Get-ADGroupMember. As with the Step Three suites,
    they do not assert which PASS/FAIL Write-Host line the script prints for a given
    query-back result, since Write-Host is not mocked; that remains covered only by
    the live-environment validation in Lab 02.

    Run with:
        Invoke-Pester -Path .\Add-LabGroupMembers.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Add-LabGroupMembers.ps1'

    # Writes a throwaway CSV to TestDrive: and returns its drive-qualified path.
    # TestDrive: is used directly (rather than the $TestDrive path variable) so the
    # path resolves correctly regardless of which scope calls this helper from.
    function script:New-TestCsv {
        param (
            [Parameter(Mandatory)] [string]$Content
        )

        $path = "TestDrive:\members-$([guid]::NewGuid().ToString('N')).csv"
        Set-Content -Path $path -Value $Content
        $path
    }
}

Describe 'Add-LabGroupMembers.ps1' {

    BeforeEach {
        # Add-ADGroupMember and Get-ADGroupMember never need different behavior between
        # tests below (a no-op write and an empty membership query-back are enough for
        # every test to exercise its own assertions), so both are registered once here,
        # the same reasoning Remove-LabUser.Tests.ps1 used for its write cmdlets in
        # Step Three. Get-ADGroup and Get-ADUser vary per test (existence, not-found,
        # and error cases), so each Context below defines them itself rather than
        # relying on a shared default that a later mock would need to override.
        Mock -CommandName Add-ADGroupMember -MockWith {}
        Mock -CommandName Get-ADGroupMember -MockWith { @() }
    }

    Context 'CSV header validation' {

        BeforeEach {
            Mock -CommandName Get-ADGroup -MockWith {}
            Mock -CommandName Get-ADUser -MockWith {}
        }

        It 'aborts without querying Active Directory when the GroupName column is missing' {
            $csvPath = New-TestCsv -Content "SamAccountName`ntuser01"

            { & $script:ScriptPath -CsvPath $csvPath } | Should -Not -Throw

            Should -Invoke Get-ADGroup -Times 0
            Should -Invoke Get-ADUser -Times 0
            Should -Invoke Add-ADGroupMember -Times 0
        }

        It 'aborts without querying Active Directory when the SamAccountName column is missing' {
            $csvPath = New-TestCsv -Content "GroupName`nIT-Admins"

            { & $script:ScriptPath -CsvPath $csvPath } | Should -Not -Throw

            Should -Invoke Get-ADGroup -Times 0
            Should -Invoke Get-ADUser -Times 0
            Should -Invoke Add-ADGroupMember -Times 0
        }

        It 'does not abort and queries the group when both required columns are present' {
            Mock -CommandName Get-ADGroup -MockWith { [PSCustomObject]@{ Name = 'IT-Admins' } }
            Mock -CommandName Get-ADUser -MockWith { [PSCustomObject]@{ SamAccountName = 'tuser01' } }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Get-ADGroup -Times 1
        }
    }

    Context 'Group existence check' {

        It 'skips the batch and adds no members when the group does not exist' {
            Mock -CommandName Get-ADGroup -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                    'Cannot find an object with identity matching the specified criteria.'
                )
            }
            Mock -CommandName Get-ADUser -MockWith { [PSCustomObject]@{ SamAccountName = 'tuser01' } }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nGhost-Group,tuser01"

            { & $script:ScriptPath -CsvPath $csvPath } | Should -Not -Throw

            Should -Invoke Add-ADGroupMember -Times 0
        }

        It 'skips the batch and adds no members when the group query fails unexpectedly' {
            Mock -CommandName Get-ADGroup -MockWith { throw 'The RPC server is unavailable.' }
            Mock -CommandName Get-ADUser -MockWith { [PSCustomObject]@{ SamAccountName = 'tuser01' } }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,tuser01"

            { & $script:ScriptPath -CsvPath $csvPath } | Should -Not -Throw

            Should -Invoke Add-ADGroupMember -Times 0
        }

        It 'still processes a later group in the same CSV after an earlier group is skipped' {
            Mock -CommandName Get-ADGroup -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'Ghost-Group' } -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                    'Cannot find an object with identity matching the specified criteria.'
                )
            }
            Mock -CommandName Get-ADGroup -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'IT-Admins' } -MockWith {
                [PSCustomObject]@{ Name = 'IT-Admins' }
            }
            Mock -CommandName Get-ADUser -MockWith { [PSCustomObject]@{ SamAccountName = 'tuser01' } }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nGhost-Group,tuser01`nIT-Admins,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['Identity'])" -eq 'IT-Admins'
            }
            Should -Invoke Add-ADGroupMember -Times 0 -ParameterFilter {
                "$($PesterBoundParameters['Identity'])" -eq 'Ghost-Group'
            }
        }
    }

    Context 'Partial-success member validation' {

        BeforeEach {
            Mock -CommandName Get-ADGroup -MockWith { [PSCustomObject]@{ Name = 'IT-Admins' } }
        }

        It 'excludes a nonexistent member from the batch but still adds the valid member' {
            Mock -CommandName Get-ADUser -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'ghost01' } -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                    'Cannot find an object with identity matching the specified criteria.'
                )
            }
            Mock -CommandName Get-ADUser -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'tuser01' } -MockWith {
                [PSCustomObject]@{ SamAccountName = 'tuser01' }
            }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,ghost01`nIT-Admins,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'tuser01'
            }
            Should -Invoke Add-ADGroupMember -Times 0 -ParameterFilter {
                @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'ghost01'
            }
        }

        It 'excludes a member whose lookup fails unexpectedly but still adds the valid member' {
            Mock -CommandName Get-ADUser -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'brokenuser' } -MockWith {
                throw 'The RPC server is unavailable.'
            }
            Mock -CommandName Get-ADUser -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'tuser01' } -MockWith {
                [PSCustomObject]@{ SamAccountName = 'tuser01' }
            }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,brokenuser`nIT-Admins,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'tuser01'
            }
            Should -Invoke Add-ADGroupMember -Times 0 -ParameterFilter {
                @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'brokenuser'
            }
        }

        It 'does not call Add-ADGroupMember when every requested member in the batch is invalid' {
            Mock -CommandName Get-ADUser -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                    'Cannot find an object with identity matching the specified criteria.'
                )
            }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,ghost01"

            { & $script:ScriptPath -CsvPath $csvPath } | Should -Not -Throw

            Should -Invoke Add-ADGroupMember -Times 0
        }
    }

    Context 'Grouping by GroupName' {

        BeforeEach {
            Mock -CommandName Get-ADGroup -MockWith { [PSCustomObject]@{ Name = 'IT-Admins' } }
            Mock -CommandName Get-ADUser -MockWith { [PSCustomObject]@{ SamAccountName = 'placeholder' } }
        }

        It 'makes exactly one Add-ADGroupMember call for a group with multiple CSV rows' {
            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,tuser01`nIT-Admins,jdoe2"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['Identity'])" -eq 'IT-Admins' -and
                @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'tuser01' -and
                @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'jdoe2'
            }
        }

        It 'makes one Add-ADGroupMember call per distinct group in the same CSV' {
            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,tuser01`nLinux-Admins,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Add-ADGroupMember -Times 2 -Exactly
        }
    }

    Context 'Query-back validation pattern' {

        BeforeEach {
            Mock -CommandName Get-ADGroup -MockWith { [PSCustomObject]@{ Name = 'IT-Admins' } }
            Mock -CommandName Get-ADUser -MockWith { [PSCustomObject]@{ SamAccountName = 'tuser01' } }
        }

        It 're-queries group membership with Get-ADGroupMember after adding, rather than trusting Add-ADGroupMember' {
            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nIT-Admins,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Get-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                "$($PesterBoundParameters['Identity'])" -eq 'IT-Admins'
            }
        }

        It 'does not call Get-ADGroupMember for a group whose batch was skipped' {
            Mock -CommandName Get-ADGroup -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                    'Cannot find an object with identity matching the specified criteria.'
                )
            }

            $csvPath = New-TestCsv -Content "GroupName,SamAccountName`nGhost-Group,tuser01"

            & $script:ScriptPath -CsvPath $csvPath

            Should -Invoke Get-ADGroupMember -Times 0
        }
    }
}
