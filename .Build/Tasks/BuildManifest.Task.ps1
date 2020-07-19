
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
    

        $functions = Get-ChildItem -Path "$ModuleName\Public\*.ps1" -ErrorAction 'Ignore' |
            Where-Object 'Name' -notmatch 'Tests'

        if ($functions) {
            'Setting FunctionsToExport...'
            Set-ModuleFunctions -Name $ManifestPath -FunctionsToExport $functions.BaseName
        }
    }
}