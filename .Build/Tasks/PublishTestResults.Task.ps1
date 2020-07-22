task PublishTestResults {
    $TestResultFiles=(Get-ChildItem "$($Env:BHBuildOutput)\*.xml" -Exclude 'CodeCoverage_*')
    switch ($Env:BHBuildSystem) {
        "AppVeyor" {
            # Upload Pester and ScriptAnalyzer output; leverage Add-TestResultToAppVeyor from BuildHelpers module
            Write-Build Green "Uploading test results [$($TestResultFiles.Name -join ', ')] to Appveyor"
            Add-TestResultToAppVeyor -TestFile ($TestResultFiles.FullName)
            break;
        }
        default {
            Write-Warning "Unknown build system: [$_]. Skipping test result publishing"
        }
    }
}