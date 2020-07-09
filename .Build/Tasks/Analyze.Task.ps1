task Analyze {
    $params = @{
        IncludeDefaultRules = $true
        Recurse             = $true
        Path                = $Env:BHModulePath
        Settings            = "$ModuleRoot\.Build\ScriptAnalyzerSettings.psd1"
    }

    "Analyzing $($Env:BHModulePath)..."
    $results = Invoke-ScriptAnalyzer @params
    if ($results) {
        'One or more PSScriptAnalyzer errors/warnings were found.'
        'Please investigate or add the required SuppressMessage attribute.'
        # Export NUnit file if Export-NUnitXML command is available
        if (Get-Command 'Export-NUnitXML' -ErrorAction 'SilentlyContinue') {
            Export-NUnitXml -ScriptAnalyzerResult $results -Path $Script:ScriptAnalyzerFile
        }
        $results | Format-Table -AutoSize
    }
}
