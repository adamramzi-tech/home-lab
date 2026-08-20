<#
.SYNOPSIS
    Registers Invoke-LabHealthReport.ps1 as a daily Windows Task Scheduler
    job on WIN11-CLIENT01, per this lab's Design Decision 5.

.DESCRIPTION
    Infrastructure Automation and Scripting track, Lab 05 (Scheduled Health
    Reporting), Step Six-B. This is the track's first state-changing script:
    every prior script in the lab is a read-only query, and this one
    registers a scheduled task. That difference has consequences this file
    is built around rather than working past.

    Per Design Decision 5, the task action is fixed: `powershell.exe` with
    the exact argument string Step Six-A already proved runs clean with no
    prompt (`-NoProfile -NonInteractive -ExecutionPolicy Bypass -File
    <ScriptPath> -SecretsDirectory <SecretsDirectory> -ReportDirectory
    <ReportDirectory>`), built from this function's own -ScriptPath,
    -SecretsDirectory, and -ReportDirectory parameters rather than
    hardcoded, so the Pester suite can assert the built string matches
    Step Six-A's validated command line without re-typing it as a literal.
    The trigger is daily at -TriggerTime (defaulting to 07:00 local, per
    Design Decision 3's "an unhealthy night has to leave something an
    operator finds the next morning"); settings are -StartWhenAvailable and
    an -ExecutionTimeLimitMinutes-minute limit (defaulting to 15, per
    Design Decision 5), both built with New-ScheduledTaskSettingsSet.

    Register-ScheduledTask itself is where this script departs from what
    Design Decision 5 originally anticipated (New-ScheduledTaskAction,
    New-ScheduledTaskTrigger, New-ScheduledTaskPrincipal, and
    New-ScheduledTaskSettingsSet). Get-Help Register-ScheduledTask -Full,
    checked live before this script was written rather than assumed, shows
    four parameter sets, and the one built around -Principal (Xml, User,
    Principal, Object are the set names) carries no -Password parameter at
    all; only the Xml, User, and Object sets do. A Principal built with
    New-ScheduledTaskPrincipal -LogonType Password has no way to receive a
    stored password through the -Principal parameter set, which would leave
    Register-ScheduledTask either failing outright or falling back to its
    own GUI password dialog, the same category of window-station prompt
    that already failed to accept input in this environment's remote
    session (Step One). This script therefore skips New-ScheduledTaskPrincipal
    and -Principal entirely and registers through the User parameter set
    instead: -User, -Password, and -RunLevel passed directly to
    Register-ScheduledTask, which is also the only parameter set in the
    Get-Help output that accepts a plaintext -Password at all. Whether this
    parameter set actually produces -LogonType Password on the registered
    task, which Design Decision 5 requires, is verified live in Step Six-B
    itself with Get-ScheduledTask -TaskName <name> | Select-Object
    -ExpandProperty Principal, rather than assumed from this reasoning
    alone.

    The run-as identity is accepted as a single -RunAsCredential
    [PSCredential], never as separate username and password parameters,
    the same discipline every credential in this lab uses and the specific
    thing that keeps this script clear of PSAvoidUsingUserNameAndPasswordParams.
    The plaintext password Register-ScheduledTask's -Password parameter
    requires is unwrapped only at that call site, via
    $RunAsCredential.GetNetworkCredential().Password, and is never assigned
    to an intermediate variable, written to the console, or placed on this
    function's returned object.

    Register- is on PSScriptAnalyzer's state-changing-verb list, so this
    function declares [CmdletBinding(SupportsShouldProcess = $true)] and
    gates the actual Register-ScheduledTask call behind
    $PSCmdlet.ShouldProcess(...), rather than dodging the rule with a
    different verb the way Step Five's ConvertTo-LabHealthReportHtml
    renamed its way around PSUseShouldProcessForStateChangingFunctions.
    This is the first script in the track to implement ShouldProcess for
    real, since it is the first one that actually changes state.

    Re-running this script against a task name that already exists is
    given a defined behavior rather than left to fail obscurely inside
    Register-ScheduledTask. Get-ScheduledTask is queried first (a
    read-only call, made unconditionally, outside the ShouldProcess gate,
    since it is a precondition check rather than the state change itself);
    if a task by that name already exists and -Force was not supplied,
    this function throws a clear error naming the task and directing the
    caller to -Force rather than letting Register-ScheduledTask's own
    already-exists behavior surface first. -Force, when supplied, is
    passed through to Register-ScheduledTask's own -Force parameter, which
    is what actually suppresses its confirmation prompt on overwrite.

    As with every top-level parameter block in this lab, none of the
    parameters below carry a Mandatory attribute, so dot-sourcing this file
    never prompts. The standalone guard at the bottom of this file, which
    only runs when this file is executed directly rather than dot-sourced,
    resolves a missing -RunAsCredential by prompting for a password only,
    not a full Get-Credential prompt: Design Decision 5 fixes the run-as
    account to labadmin, so the username needs no prompt, and Get-Credential's
    dialog has already failed to accept input in this environment's remote
    session once (Step One), which console-based Read-Host resolved there
    and resolves here the same way, via Read-Host -AsSecureString rather
    than Get-Credential. The resulting SecureString's own Length is checked
    for zero before building the [PSCredential]. This is not a guard
    against the [PSCredential] constructor itself, which accepts a
    zero-length SecureString without complaint, the same property this
    lab's own test suites already rely on when building test credentials
    from [System.Security.SecureString]::new(); it is the same class of
    check Step Five's -ReportDirectory fix added, an explicit validation
    that stops a blank prompt from silently producing a credential with an
    empty password and continuing into a broken registration instead of
    failing loudly.

    Registration itself requires an elevated PowerShell session on
    WIN11-CLIENT01, a separate requirement from the non-elevated session
    the scheduled job's own Get-Service call needs (Step One), per Design
    Decision 5.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [PSCredential]$RunAsCredential,

    [Parameter(Mandatory = $false)]
    [string]$TaskName = 'LabHealthReport',

    [Parameter(Mandatory = $false)]
    [string]$TaskPath = '\',

    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = 'C:\Scripts\Invoke-LabHealthReport.ps1',

    [Parameter(Mandatory = $false)]
    [string]$SecretsDirectory = 'C:\Secrets',

    [Parameter(Mandatory = $false)]
    [string]$ReportDirectory = 'C:\Reports',

    [Parameter(Mandatory = $false)]
    [datetime]$TriggerTime = '07:00',

    [Parameter(Mandatory = $false)]
    [int]$ExecutionTimeLimitMinutes = 15,

    [Parameter(Mandatory = $false)]
    [string]$Description = 'Runs the Lab 05 environment health report (AD service health, Wazuh agent status, Docker service status) unattended. Registered by Register-LabHealthReportTask.ps1 per Design Decision 5.',

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

function Register-LabHealthReportTask {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCredential]$RunAsCredential,

        [Parameter(Mandatory = $false)]
        [string]$TaskName = 'LabHealthReport',

        [Parameter(Mandatory = $false)]
        [string]$TaskPath = '\',

        [Parameter(Mandatory = $false)]
        [string]$ScriptPath = 'C:\Scripts\Invoke-LabHealthReport.ps1',

        [Parameter(Mandatory = $false)]
        [string]$SecretsDirectory = 'C:\Secrets',

        [Parameter(Mandatory = $false)]
        [string]$ReportDirectory = 'C:\Reports',

        [Parameter(Mandatory = $false)]
        [datetime]$TriggerTime = '07:00',

        [Parameter(Mandatory = $false)]
        [int]$ExecutionTimeLimitMinutes = 15,

        [Parameter(Mandatory = $false)]
        [string]$Description = 'Runs the Lab 05 environment health report (AD service health, Wazuh agent status, Docker service status) unattended. Registered by Register-LabHealthReportTask.ps1 per Design Decision 5.',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Read-only precondition check, made unconditionally rather than inside
    # the ShouldProcess gate below: whether the call would even be valid
    # does not depend on whether this run is a real change or a -WhatIf
    # preview.
    $existingTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue

    if ($existingTask -and -not $Force) {
        throw "A scheduled task named '$TaskName' already exists at path '$TaskPath'. Supply -Force to overwrite it."
    }

    # Built from this function's own parameters so the Pester suite can
    # assert the exact string, rather than a literal repeated here, matches
    # the command line Step Six-A already validated runs clean with no
    # prompt.
    $argumentList = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File {0} -SecretsDirectory {1} -ReportDirectory {2}' -f `
        $ScriptPath, $SecretsDirectory, $ReportDirectory

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argumentList
    $trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes $ExecutionTimeLimitMinutes)

    if ($PSCmdlet.ShouldProcess($TaskName, 'Register scheduled task')) {
        # -User/-Password/-RunLevel, not -Principal: see this file's own
        # .DESCRIPTION for why the -Principal parameter set cannot carry a
        # password. The plaintext password is unwrapped here, at this call
        # site only, and held in no variable of its own.
        Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings `
            -User $RunAsCredential.UserName -Password $RunAsCredential.GetNetworkCredential().Password -RunLevel Limited `
            -Description $Description -Force:$Force
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $RunAsCredential) {
        # Design Decision 5 fixes the run-as account to labadmin, so only
        # the password needs to be resolved interactively. Read-Host
        # -AsSecureString, not Get-Credential: Get-Credential's dialog
        # already failed to accept input in this environment's remote
        # session once (Step One), and console-based Read-Host is what
        # resolved it there.
        $runAsPassword = Read-Host -Prompt "Password for the scheduled task's run-as account (CORP\labadmin)" -AsSecureString

        # [PSCredential]::new() accepts a zero-length SecureString without
        # throwing, so a blank Read-Host response would otherwise proceed
        # silently into a credential with an empty password. Checked
        # explicitly here, the same fail-loudly pattern Step Five's
        # -ReportDirectory fix established for a blank prompt.
        if ($runAsPassword.Length -eq 0) {
            throw "A password is required to register the scheduled task; the prompt was left empty."
        }

        $RunAsCredential = [PSCredential]::new('CORP\labadmin', $runAsPassword)
    }

    $registeredTask = Register-LabHealthReportTask -RunAsCredential $RunAsCredential -TaskName $TaskName -TaskPath $TaskPath `
        -ScriptPath $ScriptPath -SecretsDirectory $SecretsDirectory -ReportDirectory $ReportDirectory -TriggerTime $TriggerTime `
        -ExecutionTimeLimitMinutes $ExecutionTimeLimitMinutes -Description $Description -Force:$Force

    if ($registeredTask) {
        $registeredTask | Select-Object TaskName, TaskPath, State | Format-Table -AutoSize
        Write-Output "Scheduled task '$TaskName' registered. Verify with: Get-ScheduledTask -TaskName '$TaskName' | Select-Object -ExpandProperty Principal"
    }
}
