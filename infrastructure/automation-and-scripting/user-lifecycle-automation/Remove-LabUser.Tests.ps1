<#
.SYNOPSIS
    Pester unit tests for Remove-LabUser.ps1, using mocked Active Directory cmdlets.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 03 (Static Analysis and Unit
    Testing), Step Three. Mocks the full Active Directory cmdlet surface
    Remove-LabUser.ps1 calls (Get-ADUser x2, Disable-ADAccount,
    Get-ADPrincipalGroupMembership x2, Remove-ADPrincipalGroupMembership), so the suite
    runs without a live domain and cannot disable or modify a real AD account.

    PHASE 1 (harness smoke test): unlike New-LabUser.ps1, both of this script's
    Get-ADUser calls request the identical set of properties (-Properties Enabled,
    PrimaryGroup), so they do not need to be differentiated by ParameterFilter the way
    New-LabUser.ps1's pre-flight/validation calls did; a single default mock covers
    both in the happy path.

    A second AD-type-coercion gotcha, beyond the one New-LabUser.Tests.ps1 hit with
    Add-ADGroupMember, surfaced while proving this harness: Remove-ADPrincipalGroupMembership's
    -MemberOf is typed [Microsoft.ActiveDirectory.Management.ADPrincipal] on the real
    cmdlet, and the script passes it the group object returned by
    Get-ADPrincipalGroupMembership directly (`-MemberOf $group`). A plain string bound
    successfully for Add-ADGroupMember's -Identity/-Members because AD's identity-type
    converter recognizes strings directly; a fabricated PSCustomObject does not go
    through that converter, and PowerShell's fallback property-adapter conversion
    failed outright ("Cannot bind parameter 'MemberOf' ... The adapter cannot set the
    value of property 'Name'"), because ADPrincipal's properties are not
    adapter-settable. Casting the identity string to the real ADPrincipal type first
    (the same conversion path proven to work for -Identity/-Members) produces a
    genuine ADPrincipal instance, which binds without that adapter failure.

    A related gotcha, confirmed via a diagnostic mock dump against WIN11-CLIENT01,
    applies to ParameterFilter/Should -Invoke checks against the bound -MemberOf
    value: the value that actually arrives is a freshly-reconstructed
    Microsoft.ActiveDirectory.Management.ADGroup[] built from the identity string
    used to construct it, not the specific object instance this test created, so the
    Add-Member -Force DistinguishedName/Name overrides below do not survive parameter
    binding (they live on the PSObject wrapper, not the reconstructed CLR object) and
    read back empty. What does survive is .ToString(), which reproduces the full
    DistinguishedName the object was cast from. ParameterFilter checks below compare
    against "$($PesterBoundParameters['MemberOf'])" for that reason; the Add-Member
    overrides are kept only because the script's own Where-Object filter and
    Write-Host narration read them directly off the object Get-ADPrincipalGroupMembership
    returns, before any parameter binding happens.

    Scope: these tests assert Remove-LabUser.ps1's decision logic, the pre-flight
    not-found/error checks, that the account is disabled, that removal is applied to
    every non-primary group membership and never to the primary group, and that the
    script re-queries Active Directory after writing (the query-back validation
    pattern). As with New-LabUser.Tests.ps1, they do not assert which PASS/FAIL
    Write-Host line the script prints for a given query-back result, since Write-Host
    is not mocked; those mocked query-back results are static, so this script's own
    "still enabled" / "not removed" narration is expected and not a defect, only
    live-environment validation (Lab 01) confirms the actual PASS narration.

    Run with:
        Invoke-Pester -Path .\Remove-LabUser.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Remove-LabUser.ps1'

    # See the AD-type-coercion note above: builds a real ADPrincipal instance (not a
    # fabricated PSCustomObject) so it binds cleanly to Remove-ADPrincipalGroupMembership's
    # typed -MemberOf parameter, then overrides DistinguishedName/Name to the values this
    # test controls so the script's own filter and narration logic see real data.
    function script:New-MockADPrincipal {
        param (
            [Parameter(Mandatory)] [string]$DistinguishedName,
            [Parameter(Mandatory)] [string]$Name
        )

        $principal = [Microsoft.ActiveDirectory.Management.ADPrincipal]$DistinguishedName
        $principal | Add-Member -Force -NotePropertyName DistinguishedName -NotePropertyValue $DistinguishedName
        $principal | Add-Member -Force -NotePropertyName Name -NotePropertyValue $Name
        $principal
    }
}

Describe 'Remove-LabUser.ps1' {

    # Shared by every test below: neither Disable-ADAccount nor
    # Remove-ADPrincipalGroupMembership need different behavior between tests (always a
    # no-op), and Should -Invoke requires a registered Mock for a command to exist in
    # scope even to assert it was called zero times.
    BeforeEach {
        Mock -CommandName Disable-ADAccount -MockWith {}
        Mock -CommandName Remove-ADPrincipalGroupMembership -MockWith {}
    }

    Context 'Pre-flight validation' {

        # Each It here defines its own Get-ADUser mock rather than sharing one from an
        # outer BeforeEach, so there is never more than one registered behavior for
        # Get-ADUser in a given test (same reasoning as New-LabUser.Tests.ps1).

        It 'does not disable the account or touch group membership when it does not exist' {
            Mock -CommandName Get-ADUser -MockWith {
                throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new(
                    'Cannot find an object with identity matching the specified criteria.'
                )
            }

            { & $script:ScriptPath -SamAccountName 'tuser01' } | Should -Not -Throw

            Should -Invoke Disable-ADAccount -Times 0
            Should -Invoke Remove-ADPrincipalGroupMembership -Times 0
        }

        It 'does not disable the account or touch group membership when the pre-flight query fails unexpectedly' {
            Mock -CommandName Get-ADUser -MockWith { throw 'The RPC server is unavailable.' }

            { & $script:ScriptPath -SamAccountName 'tuser01' } | Should -Not -Throw

            Should -Invoke Disable-ADAccount -Times 0
            Should -Invoke Remove-ADPrincipalGroupMembership -Times 0
        }
    }

    Context 'Happy path' {

        # Both of the script's Get-ADUser calls request the same -Properties, so one
        # default (no ParameterFilter) mock covers both. PrimaryGroup is set to match
        # the primary group's DistinguishedName in the Get-ADPrincipalGroupMembership
        # mock below, so the primary-group-exclusion filter has something real to
        # exclude.
        BeforeEach {
            Mock -CommandName Get-ADUser -MockWith {
                [PSCustomObject]@{
                    Enabled           = $true
                    PrimaryGroup      = 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa'
                    DistinguishedName = 'CN=Test User,OU=User Accounts,DC=corp,DC=home,DC=arpa'
                }
            }

            # Three memberships: the primary group (must be excluded from removal) and
            # two removable groups. Used for both the pre-removal $groups computation
            # and the post-removal $remainingGroups validation query; the script does
            # not depend on those two calls returning different results.
            Mock -CommandName Get-ADPrincipalGroupMembership -MockWith {
                @(
                    (New-MockADPrincipal -DistinguishedName 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa' -Name 'Domain Users')
                    (New-MockADPrincipal -DistinguishedName 'CN=IT-Admins,OU=Groups,DC=corp,DC=home,DC=arpa' -Name 'IT-Admins')
                    (New-MockADPrincipal -DistinguishedName 'CN=Linux-Admins,OU=Groups,DC=corp,DC=home,DC=arpa' -Name 'Linux-Admins')
                )
            }
        }

        Context 'Account offboarding' {

            It 'does not crash, disables the account, and processes the removable-group loop' {
                { & $script:ScriptPath -SamAccountName 'tuser01' } | Should -Not -Throw

                Should -Invoke Disable-ADAccount -Times 1
            }

            It 'disables the account exactly once' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                Should -Invoke Disable-ADAccount -Times 1 -Exactly
            }
        }

        Context 'Primary-group exclusion' {

            It 'removes membership from each non-primary group' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                Should -Invoke Remove-ADPrincipalGroupMembership -Times 2 -Exactly
            }

            It 'removes the IT-Admins membership' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                Should -Invoke Remove-ADPrincipalGroupMembership -Times 1 -Exactly -ParameterFilter {
                    "$($PesterBoundParameters['MemberOf'])" -eq 'CN=IT-Admins,OU=Groups,DC=corp,DC=home,DC=arpa'
                }
            }

            It 'removes the Linux-Admins membership' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                Should -Invoke Remove-ADPrincipalGroupMembership -Times 1 -Exactly -ParameterFilter {
                    "$($PesterBoundParameters['MemberOf'])" -eq 'CN=Linux-Admins,OU=Groups,DC=corp,DC=home,DC=arpa'
                }
            }

            It 'never removes the primary group (Domain Users) membership' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                Should -Invoke Remove-ADPrincipalGroupMembership -Times 0 -ParameterFilter {
                    "$($PesterBoundParameters['MemberOf'])" -eq 'CN=Domain Users,CN=Users,DC=corp,DC=home,DC=arpa'
                }
            }
        }

        Context 'Query-back validation pattern' {

            It 're-queries the account after offboarding, rather than trusting Disable-ADAccount' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                # Called once for the pre-flight check and once for the post-offboarding
                # validation query; asserting both calls happened, not just the first.
                Should -Invoke Get-ADUser -Times 2 -Exactly
            }

            It 're-queries group membership after removal, rather than trusting Remove-ADPrincipalGroupMembership' {
                & $script:ScriptPath -SamAccountName 'tuser01'

                # Called once to compute $groups before removal and once for
                # $remainingGroups after; asserting both calls happened.
                Should -Invoke Get-ADPrincipalGroupMembership -Times 2 -Exactly
            }
        }
    }
}
