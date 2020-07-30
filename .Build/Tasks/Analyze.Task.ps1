task Analyze {
    $params = @{
        IncludeDefaultRules = $true
        Recurse             = $true
        Path                = $Env:BHModulePath
        Settings            = "$($Env:BHProjectPath)\.Build\ScriptAnalyzerSettings.psd1"
    }

    "Analyzing $($Env:BHModulePath)..."
    $Script:PSScriptAnalyzerResults = $null
    $Script:PSScriptAnalyzerResults = Invoke-ScriptAnalyzer @params
    if ($Script:PSScriptAnalyzerResults) {
        # Export NUnit file if Export-NUnitXML command is available
        if (Get-Command 'Export-NUnitXML' -ErrorAction 'SilentlyContinue') {
            Export-NUnitXml -ScriptAnalyzerResult $Script:PSScriptAnalyzerResults -Path $Script:ScriptAnalyzerFile -TestFileName (Split-Path -Leaf $Script:ScriptAnalyzerFile)
        }
        $Script:PSScriptAnalyzerResults | Format-Table -AutoSize
    }
}
