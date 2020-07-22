task PublishCodeCoverage {
    $CodeCovFiles=(Get-ChildItem "$($Env:BHBuildOutput)\CodeCoverage*.xml")
    switch ($Env:BHBuildSystem) {
        "AppVeyor" {
            if ($null -ne $CodeCovFiles) {
                # Upload code coverage report to CodeCov.io
                Invoke-WebRequest -Uri 'https://codecov.io/bash' -OutFile codecov.sh
                $env:PATH = 'C:\msys64\usr\bin;' + $env:PATH
                bash codecov.sh -f "CodeCoverage*.xml" -A "-s"
            } Else {
                Write-Warning "No code coverage files found to upload"                
            }
            break;
        }
        default {
            Write-Warning "Unknown build system: [$_]. Skipping code coverage publishing"
        }
    }
}