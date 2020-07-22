task PublishTestResults {
    $TestResultFiles=(Get-ChildItem "$($Env:BHBuildOutput)\*.xml" -Exclude 'CodeCoverage_*')
    switch ($Env:BHBuildSystem) {
        "AppVeyor" {
            if ($null -ne $TestResultFiles) {
                # Upload Pester and ScriptAnalyzer output; leverage Add-TestResultToAppVeyor from BuildHelpers module
                Write-Build Green "Uploading test results [$($TestResultFiles.Name -join ', ')] to Appveyor"
                Add-TestResultToAppVeyor -TestFile ($TestResultFiles.FullName)
            } Else {
                Write-Warning "No test results found to upload"
            }
            break;
        }
        default {
            Write-Warning "Unknown build system: [$_]. Skipping test result publishing"
        }
    }
}