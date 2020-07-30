task FailBuildOnPSSAFail {
    if ($null -ne $Script:PSScriptAnalyzerResults) {
        Throw 'One or more PSScriptAnalyzer errors/warnings were found. Please investigate or add the required SuppressMessage attribute.'
    } Else {
        Write-Build Green "All PSScriptAnalyzer tests succeeded."
    }
}