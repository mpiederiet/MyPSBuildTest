Function Invoke-PesterFromTask ([switch]$IsDev) {
    # Force loading the latest version of Pester because of the new PesterConfiguration
    Import-Module Pester -MinimumVersion 5.0
    # Create new Pester configuration object
    $PesterConfiguration=[PesterConfiguration]::default

    if ($IsDev){
        $CodeCoverageFiles=[string[]](Get-ChildItem -Recurse -Path $Script:Source -Include '*.ps1','*.psm1'|Select-Object -Expand FullName)
        $Tag='Dev'
    } Else {
        $CodeCoverageFiles=[string[]](Get-ChildItem -Recurse -Path $Script:Destination -Include '*.ps1','*.psm1'|Select-Object -Expand FullName)
        $Tag='Build'
    }
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
            Tag = $Tag
        }
        Should = @{
            ErrorAction = 'Continue'
        }
        CodeCoverage = @{
            Enabled=$True
            OutputPath=($Script:CodeCoverageFile)
            Path=$CodeCoverageFiles
        }
        Output = @{
            Verbosity='Detailed'
        }
    }

    # Run Pester with -verbose if not testing the master branch
    $Verbose = @{}

    if($env:BHBranchName -and $env:BHBranchName -notlike 'master' -or $VerbosePreference -eq 'Continue') {
        $Verbose.add("Verbose",$True)
    }
    $Script:PesterResults = Invoke-Pester @Verbose -Configuration $PesterConfiguration

    # Fix filename in Pester NUnit XML
    [XML]$PesterFile=Get-Content $Script:PesterResults.Configuration.TestResult.OutputPath.Value -Encoding $Script:PesterResults.Configuration.TestResult.OutputEncoding.Value
    $PesterFile.'test-results'.'test-suite'.type='PowerShell'
    $PesterFile.'test-results'.'test-suite'.name=[string](Split-Path -Leaf $Script:PesterResults.Configuration.TestResult.OutputPath.Value)
    $PesterFile.Save($Script:PesterResults.Configuration.TestResult.OutputPath.Value)
}

task Pester {
    Invoke-PesterFromTask
}

task PesterDev {
    Invoke-PesterFromTask -IsDev
}