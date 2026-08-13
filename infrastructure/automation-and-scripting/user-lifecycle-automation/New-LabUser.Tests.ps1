<#
.SYNOPSIS
    Pester unit tests for New-LabUser.ps1, using mocked Active Directory cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 03 (Static Analysis and Unit
    Testing), Step Three. Mocks the full Active Directory cmdlet surface
    New-LabUser.ps1 calls (Get-ADUser x2, New-ADUser, Add-ADGroupMember,
    Get-ADPrincipalGroupMembership), so the suite runs without a live domain and
    cannot create a real AD account.

    Scope: these tests assert New-LabUser.ps1's decision logic, the pre-flight
    duplicate/error checks, the parameters passed to New-ADUser, role group and
    Linux-Admins group assignment, and that the script re-queries Active Directory
    after writing (the query-back validation pattern) rather than trusting the write
    cmdlets blindly. They do not assert which PASS/FAIL Write-Host line the script
    prints for a given query-back result: PSAvoidUsingWriteHost is intentionally
    excluded for this library (see PSScriptAnalyzerSettings.psd1) because the colored
    status output is operator-facing display, and per this lab's testing approach
    Write-Host itself is not mocked. The specific status line each validation branch
    selects therefore remains covered only by the live-environment validation in Lab
    01, not by this suite; the decision that produces the input to that branch
    (querying AD back after each write) is what is under test here.

    Run with:
        Invoke-Pester -Path .\New-LabUser.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath   = Join-Path $PSScriptRoot 'New-LabUser.ps1'
    $script:TestPassword = ConvertTo-SecureString 'P@ssw0rd123!' -AsPlainText -Force
}

Describe 'New-LabUser.ps1' {

    BeforeEach {
        # Line-88 post-creation validation: Get-ADUser called WITH -Properties.
        # Shared by every test below; none of them need a different validation result.
        #
        # NOTE: Pester's -ParameterFilter scriptblock does not populate $PSBoundParameters
        # for the call being matched; it defines $PesterBoundParameters for that purpose
        # instead (confirmed against Pester 5.6.1's own source, src/functions/Mock.ps1).
        # Referencing a bound parameter directly by name (e.g. $Identity) worked for
        # New-ADUser's parameters but did not reliably resolve for Add-ADGroupMember's
        # during this suite's first run, so every ParameterFilter and Should -Invoke
        # -ParameterFilter below uses $PesterBoundParameters['Name'] consistently rather
        # than mixing the two approaches.
        Mock -CommandName Get-ADUser `
            -ParameterFilter { $PesterBoundParameters.ContainsKey('Properties') } `
            -MockWith {
                [PSCustomObject]@{
                    Enabled           = $true
                    DistinguishedName = 'CN=Test User,OU=User Accounts,DC=corp,DC=home,DC=arpa'
                }
            }

        Mock -CommandName New-ADUser -MockWith {}
        # Add-ADGroupMember's -Identity/-Members are typed
        # [Microsoft.ActiveDirectory.Management.ADGroup] / [...ADPrincipal[]] on the real
        # cmdlet, and Pester's mock proxy preserves those types, so PowerShell coerces the
        # strings the script passes (e.g. -Identity 'Domain-Users-Standard') into AD
        # objects at bind time, confirmed empirically via a diagnostic run against
        # WIN11-CLIENT01: bound $Identity is a Microsoft.ActiveDirectory.Management.ADGroup
        # whose .ToString() returns the bare name, and bound $Members is an array of
        # Microsoft.ActiveDirectory.Management.ADPrincipal with the same .ToString()
        # behavior. Should -Invoke -ParameterFilter checks below compare against
        # "$($PesterBoundParameters['Name'])" (forces .ToString()) rather than the bound
        # value directly for that reason.
        Mock -CommandName Add-ADGroupMember -MockWith {}
        Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
            @([PSCustomObject]@{ Name = 'Domain-Users-Standard' })
        }
    }

    Context 'Pre-flight validation' {

        # Each It here defines its own Line-42 pre-flight mock (Get-ADUser called
        # WITHOUT -Properties) rather than sharing one from an outer BeforeEach, so
        # there is never more than one registered behavior for that filter shape in
        # a given test and no ambiguity about which one Pester would apply.

        It 'does not create an account when one with the same SamAccountName already exists' {
            Mock -CommandName Get-ADUser `
                -ParameterFilter { -not $PesterBoundParameters.ContainsKey('Properties') } `
                -MockWith {
                    [PSCustomObject]@{
                        DistinguishedName = 'CN=Existing User,OU=User Accounts,DC=corp,DC=home,DC=arpa'
                    }
                }

            { & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword } |
                Should -Not -Throw

            Should -Invoke New-ADUser -Times 0
            Should -Invoke Add-ADGroupMember -Times 0
        }

        It 'does not create an account when the pre-flight Get-ADUser query fails unexpectedly' {
            Mock -CommandName Get-ADUser `
                -ParameterFilter { -not $PesterBoundParameters.ContainsKey('Properties') } `
                -MockWith { throw 'The RPC server is unavailable.' }

            { & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword } |
                Should -Not -Throw

            Should -Invoke New-ADUser -Times 0
            Should -Invoke Add-ADGroupMember -Times 0
        }
    }

    Context 'Happy path' {

        # Shared by every Context below: the pre-flight Get-ADUser call (no
        # -Properties) reports no existing account, so the script proceeds to create
        # one. Kept out of the outer Describe's BeforeEach and scoped to this Context
        # only, so it never coexists with the 'Pre-flight validation' Context's
        # per-test overrides of the same call.
        BeforeEach {
            Mock -CommandName Get-ADUser `
                -ParameterFilter { -not $PesterBoundParameters.ContainsKey('Properties') } `
                -MockWith {
                    throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                        'Cannot find an object with identity matching the specified criteria.'
                    )
                }
        }

        Context 'Account creation' {

            It 'does not crash and creates the account when it does not already exist' {
                { & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword } |
                    Should -Not -Throw

                Should -Invoke New-ADUser -Times 1
            }

            It 'creates the account in the default target OU when -TargetOU is not specified' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword

                Should -Invoke New-ADUser -Times 1 -Exactly -ParameterFilter {
                    $PesterBoundParameters['SamAccountName'] -eq 'tuser01' -and
                    $PesterBoundParameters['Path'] -eq 'OU=User Accounts,DC=corp,DC=home,DC=arpa'
                }
            }

            It 'creates the account in a custom target OU when -TargetOU is specified' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' `
                    -TargetOU 'OU=Contractors,DC=corp,DC=home,DC=arpa' -InitialPassword $script:TestPassword

                Should -Invoke New-ADUser -Times 1 -Exactly -ParameterFilter {
                    $PesterBoundParameters['Path'] -eq 'OU=Contractors,DC=corp,DC=home,DC=arpa'
                }
            }

            It 'derives the display name and UPN from the supplied first and last name' {
                & $script:ScriptPath -FirstName 'Jane' -LastName 'Doe' -SamAccountName 'jdoe2' -InitialPassword $script:TestPassword

                Should -Invoke New-ADUser -Times 1 -Exactly -ParameterFilter {
                    $PesterBoundParameters['Name'] -eq 'Jane Doe' -and
                    $PesterBoundParameters['DisplayName'] -eq 'Jane Doe' -and
                    $PesterBoundParameters['UserPrincipalName'] -eq 'jdoe2@corp.home.arpa'
                }
            }
        }

        Context 'Role group assignment' {

            It 'adds the account to the default role group (Domain-Users-Standard) when -RoleGroup is not specified' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword

                # -Identity/-Members are typed [ADGroup]/[ADPrincipal[]] on the real cmdlet, so
                # Pester's mock proxy binds coerced AD objects, not strings; "$(...)" forces
                # .ToString() so the comparison is against the same string form the script passed.
                Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                    "$($PesterBoundParameters['Identity'])" -eq 'Domain-Users-Standard' -and
                    @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'tuser01'
                }
            }

            It 'adds the account to a custom role group when -RoleGroup is specified' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' `
                    -RoleGroup 'IT-Admins' -InitialPassword $script:TestPassword

                Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter {
                    "$($PesterBoundParameters['Identity'])" -eq 'IT-Admins' -and
                    @($PesterBoundParameters['Members'] | ForEach-Object { "$_" }) -contains 'tuser01'
                }
            }
        }

        Context 'Linux access' {

            It 'adds the account to Linux-Admins when -LinuxAccess is specified' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' `
                    -LinuxAccess -InitialPassword $script:TestPassword

                Should -Invoke Add-ADGroupMember -Times 1 -Exactly -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'Linux-Admins' }
                Should -Invoke Add-ADGroupMember -Times 2 -Exactly
            }

            It 'does not add the account to Linux-Admins when -LinuxAccess is not specified' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword

                Should -Invoke Add-ADGroupMember -Times 0 -ParameterFilter { "$($PesterBoundParameters['Identity'])" -eq 'Linux-Admins' }
                Should -Invoke Add-ADGroupMember -Times 1 -Exactly
            }
        }

        Context 'Query-back validation pattern' {

            It 're-queries the account with -Properties after provisioning, rather than trusting New-ADUser' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword

                Should -Invoke Get-ADUser -Times 1 -Exactly -ParameterFilter { $PesterBoundParameters.ContainsKey('Properties') }
            }

            It 're-queries group membership via Get-ADPrincipalGroupMembership after provisioning' {
                & $script:ScriptPath -FirstName 'Test' -LastName 'User' -SamAccountName 'tuser01' -InitialPassword $script:TestPassword

                Should -Invoke Get-ADPrincipalGroupMembership -Times 1 -Exactly
            }
        }
    }
}
