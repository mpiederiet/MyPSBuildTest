task FailBuildOnPesterFail {
    if ($Script:PesterResults.FailedCount -gt 0) {
        Throw "Failed [$($Script:PesterResults.FailedCount)] Pester tests."
    } Else {
        Write-Build Green "All Pester tests succeeded."
    }
}