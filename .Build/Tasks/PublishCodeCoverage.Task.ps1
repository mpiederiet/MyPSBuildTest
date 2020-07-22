task PublishCodeCoverage {
    switch ($Env:BHBuildSystem) {
        "AppVeyor" {
            # Upload code coverage report to CodeCov.io
            Invoke-WebRequest -Uri 'https://codecov.io/bash' -OutFile codecov.sh
            $env:PATH = 'C:\msys64\usr\bin;' + $env:PATH
            bash codecov.sh -f "CodeCoverage*.xml" -A "-s"
            break;
        }
        default {
            Write-Warning "Unknown build system: [$_]. Skipping code coverage publishing"
        }
    }
}