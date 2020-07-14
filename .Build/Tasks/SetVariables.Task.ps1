task SetVariables {
    if ($null -eq (Get-ChildItem 'Env:BH*')) {
        Write-Verbose 'Setting Build Environment variables'
        Set-BuildEnvironment -BuildOutput $BuildOutput
    } else {
        Write-Verbose 'Build Environment variables already set'
    }

    $Script:Output=$Env:BHBuildOutput
    # BuildRoot is set by invoke-build
    #$Script:BuildRoot=$Env:BHProjectPath
    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $BuildRoot -ChildPath $BuildOutput
    }

    $Script:Source=$Env:BHModulePath
    $Script:DocsPath=Join-Path $Env:BHProjectPath 'Docs'
    $Script:Destination=Join-Path $Env:BHBuildOutput $Env:BHProjectName
    $Script:ModuleName=$Env:BHProjectName
    $Script:ManifestPath=Join-Path $Script:Destination "$ModuleName.psd1"
    $Script:ModulePath=Join-Path $Script:Destination "$ModuleName.psm1"
    $Script:ModuleRoot = $Env:BHProjectPath
    $Script:ModuleName = $Env:BHProjectName

    $Script:CodeCoverageThreshold=$CodeCoverageThreshold

    Write-Verbose "Initializing build variables" -Verbose
    Write-Verbose "  Existing BuildRoot [$BuildRoot]" -Verbose
    Write-Verbose "  DocsPath [$DocsPath]" -Verbose
    Write-Verbose "  Output [$Output]" -Verbose
    Write-Verbose "  Source [$Source]" -Verbose
    Write-Verbose "  Destination [$Destination]" -Verbose
    Write-Verbose "  ModuleName [$ModuleName]" -Verbose
    Write-Verbose "  ManifestPath [$ManifestPath]" -Verbose
    Write-Verbose "  ModulePath [$ModulePath]" -Verbose

    $Script:Folders = 'Classes', 'Includes', 'Internal', 'Private', 'Public', 'Resources'
    Write-Verbose "  Folders [$Folders]" -Verbose

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = "$($PSVersionTable.PSVersion.Major)$($PSVersionTable.PSEdition)"

    $Script:PesterTestFile = Join-Path $Output "TestResults_PS$($PSVersion)`_$TimeStamp.xml"
    Write-Verbose "  PesterTestFile [$PesterTestFile]" -Verbose
    $Script:ScriptAnalyzerFile = Join-Path $Output "ScriptAnalyzer_PS$($PSVersion)`_$TimeStamp.xml"
    Write-Verbose "  ScriptAnalyzerFile [$ScriptAnalyzerFile]" -Verbose
    $Script:CodeCoverageFile = Join-Path $Output "CodeCoverage_PS$($PSVersion)`_$TimeStamp.xml"
    Write-Verbose "  CodeCoverageFile [$CodeCoverageFile]" -Verbose

    $Script:PSRepository = 'PSGallery'
    Write-Verbose "  PSRepository [$PSRepository]" -Verbose
}
#   function taskx($Name, $Parameters) { task $Name @Parameters -Source $MyInvocation }