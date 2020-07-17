task PublishTestResults {
    $TestResultFiles=(Get-ChildItem "$($Env:BHBuildOutput)\*.xml" -Exclude 'CodeCoverage_*')
    switch ($Env:BHBuildSystem) {
        "AppVeyor" {
            # Upload Pester and ScriptAnalyzer output; leverage Add-TestResultToAppVeyor from BuildHelpers module
            Write-Build Green "Uploading test results [$($TestResultFiles.Name -join ', ')] to Appveyor"
            Add-TestResultToAppVeyor -TestFile ($TestResultFiles.FullName)
            # Upload code coverage report to CodeCov.io
            Invoke-WebRequest -Uri 'https://codecov.io/bash' -OutFile codecov.sh
            $env:PATH = 'C:\msys64\usr\bin;' + $env:PATH
            bash codecov.sh -f "CodeCoverage*.xml" -A "-s"
            break;
        }
        default {
            Write-Error "Unknown build system: $_. Skipping test result publishing"
        }
    }
}