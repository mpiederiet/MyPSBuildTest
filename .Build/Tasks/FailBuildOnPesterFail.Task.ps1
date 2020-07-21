task FailBuildOnPesterFail {
    # Pester 5 does not return a CodeCoverage object, so parse the Jacoco file to get similar results
    $CodeCoverageText=''
    if ($Script:PesterResults.Configuration.CodeCoverage.Enabled.Value -and (Test-Path $Script:PesterResults.Configuration.CodeCoverage.OutputPath.Value)) {
        $FileContents=Get-Content $Script:PesterResults.Configuration.CodeCoverage.OutputPath.Value
        if ($FileContents.Length -gt 0) {
            $CodeCoverageReport=[xml]($FileContents)
            $CodeCoverageResult=$CodeCoverageReport.SelectSingleNode('/report/counter[@type=''INSTRUCTION'']')
            $codeCoverage = [int64]($CodeCoverageResult.Covered) / ([int64]($CodeCoverageResult.Missed)+[int64]($CodeCoverageResult.Covered))
            if($codeCoverage -lt ($Script:CodeCoverageThreshold/100)) {
                $CodeCoverageText="Failed Code Coverage [{0:P}]. Threshold is {1:P}" -f $codeCoverage,($Script:CodeCoverageThreshold/100)
            }
        }
    }

    if ($Script:PesterResults.FailedCount -gt 0) {
        Throw ("Failed [$($Script:PesterResults.FailedCount)] Pester tests.",$CodeCoverageText -join ' ')
    } ElseIf ($CodeCoverageText) {
        Throw $CodeCoverageText
    }
}