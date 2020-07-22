
task BuildManifest @{
    Inputs  = {Get-ChildItem -Path $Source -Recurse -File}
    Outputs = {$ManifestPath}
    Jobs    = {
        "Updating [$ManifestPath]..."
        Copy-Item -Path "$Source\$ModuleName.psd1" -Destination $ManifestPath
        <#
        $content = Get-Content -Path "$Source\$ModuleName.psd1" -Raw -Encoding UTF8
        $content.Trim() | Set-Content -Path "$Source\$ModuleName.psd1" -Encoding UTF8
        #>

        # Pester Tests are in a separate folder ("tests"), but for safety they will be excluded here
        $functions = Get-ChildItem -Path "$ModuleName\Public\*.ps1" -ErrorAction 'Ignore' |
            Where-Object 'Name' -notlike '*.Tests.*'

        if ($functions) {
            'Setting FunctionsToExport...'
            Set-ModuleFunctions -Name $ManifestPath -FunctionsToExport $functions.BaseName
        }
    }
}