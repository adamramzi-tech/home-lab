@{
    # PSScriptAnalyzer settings for the Infrastructure Automation and Scripting
    # script library. Pin the rule set here so every run is reproducible:
    #   Invoke-ScriptAnalyzer -Path <scripts> -Settings <this file> -Recurse
    #
    # All default rules run EXCEPT those in ExcludeRules below. Every exclusion
    # is a deliberate, reviewed decision with a written justification, not a
    # silent omission (see Lab 03 Step Two and ADR-017).
    ExcludeRules = @(
        # PSAvoidUsingWriteHost -- excluded deliberately, with justification.
        #
        # The scripts in this library use Write-Host with -ForegroundColor to
        # print colored PASS / FAIL / ABORT status lines for a human operator
        # running them interactively. This is intentional operator-facing
        # display, not pipeline data: the actual report data flows through the
        # pipeline and Export-Csv, and the status lines are feedback only.
        #
        # The scripts target Windows PowerShell 5.1, where Write-Host writes to
        # the information stream (stream 6) and is therefore capturable and
        # redirectable -- the rule's core objection ("cannot be suppressed,
        # captured, or redirected") applies only prior to PS 5.0, as the rule's
        # own message notes.
        #
        # The considered alternative, migrating to Write-Information, was
        # rejected: it is silent by default and carries no -ForegroundColor, so
        # it would degrade the operator experience for no practical gain.
        'PSAvoidUsingWriteHost'
    )
}
