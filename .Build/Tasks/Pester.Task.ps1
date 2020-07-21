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
    $Script:PesterResults = Invoke-Pester @Verbose -Configuration $PesterConfiguration

    # Fix filename in Pester NUnit XML
    $NUnitText=Get-Content $Script:PesterResults.Configuration.TestResult.OutputPath.Value -Encoding $Script:PesterResults.Configuration.TestResult.OutputEncoding.Value
    $FixedText=$NUnitText -replace 'type="TestFixture" name="Pester"',"type=""PowerShell"" name=""$(Split-Path -Leaf $Script:PesterResults.Configuration.TestResult.OutputPath.Value)"""
    Out-File -InputObject $FixedText -FilePath $Script:PesterResults.Configuration.TestResult.OutputPath.Value -Encoding $Script:PesterResults.Configuration.TestResult.OutputEncoding.Value
}