task Pester {
    # Force loading the latest version of Pester because of the new PesterConfiguration
    Import-Module Pester -MinimumVersion 5.0
    # Create new Pester configuration object
    $PesterConfiguration=[PesterConfiguration]::default

    $PesterConfiguration = [PesterConfiguration]@{
        Run = @{
            Path = 'Tests'
            PassThru = $True
        }
        TestResult = @{
            Enabled = $True
            OutputPath = $PesterTestFile
            OutputEncoding = 'UTF8'
            TestSuiteName = (Split-Path -Leaf $PesterTestFile)
        }
        Filter = @{
            Tag = 'Build'
        }
        Should = @{
            ErrorAction = 'Continue'
        }
        CodeCoverage = @{
            Enabled=$True
            OutputPath=($Script:CodeCoverageFile)
            Path=[string[]](Get-ChildItem -Recurse -Path $Script:Destination -Include '*.ps1','*.psm1'|Select-Object -Expand FullName)
        }
    }

    # Run Pester with -verbose if not testing the master branch
    $Verbose = @{}
    if($env:BHBranchName -and $env:BHBranchName -notlike 'master') {
        $Verbose.add("Verbose",$True)
    }
    $results = Invoke-Pester @Verbose -Configuration $PesterConfiguration

    # Fix filename in Pester NUnit XML
    $NUnitText=Get-Content $Results.Configuration.TestResult.OutputPath.Value -Encoding $Results.Configuration.TestResult.OutputEncoding.Value
    $FixedText=$NUnitText -replace 'type="TestFixture" name="Pester"',"type=""PowerShell"" name=""$(Split-Path -Leaf $Results.Configuration.TestResult.OutputPath.Value)"""
    Out-File -InputObject $FixedText -FilePath $Results.Configuration.TestResult.OutputPath.Value -Encoding $Results.Configuration.TestResult.OutputEncoding.Value

    # Pester 5 does not return a CodeCoverage object, so parse the Jacoco file to get similar results
    $CodeCoverageText=''
    if ($Results.Configuration.CodeCoverage.Enabled.Value -and (Test-Path $Results.Configuration.CodeCoverage.OutputPath.Value)) {
        $FileContents=Get-Content $Results.Configuration.CodeCoverage.OutputPath.Value
        if ($FileContents.Length -gt 0) {
            $CodeCoverageReport=[xml]($FileContents)
            $CodeCoverageResult=$CodeCoverageReport.SelectSingleNode('/report/counter[@type=''INSTRUCTION'']')
            $codeCoverage = [int64]($CodeCoverageResult.Covered) / ([int64]($CodeCoverageResult.Missed)+[int64]($CodeCoverageResult.Covered))
            if($codeCoverage -lt ($Script:CodeCoverageThreshold/100)) {
                $CodeCoverageText="Failed Code Coverage [{0:P}]. Threshold is {1:P}" -f $codeCoverage,($Script:CodeCoverageThreshold/100)
            }
        }
    }

    if ($results.FailedCount -gt 0) {
        Write-Error ("Failed [$($results.FailedCount)] Pester tests.",$CodeCoverageText -join ' ')
    } ElseIf ($CodeCoverageText) {
        Write-Error $CodeCoverageText
    }
}