[cmdletBinding()]
Param (
    [Parameter(Position=0)]
    $Tasks,

    [String]
    $BuildOutput = 'BuildOutput',

    [switch]
    $InstallDependencies,

    [String[]]
    $GalleryRepository,

    [Uri]
    $GalleryProxy,

    $CodeCoverageThreshold = 80
)
Write-Debug "$($MyInvocation.ScriptName): $($PSBoundParameters | out-string)"
function Install-Dependencies {
    [CmdletBinding()]
    param()

    if (!(Get-PackageProvider -Name NuGet -ForceBootstrap)) {
        $providerBootstrapParams = @{
            Name = 'nuget'
            force = $true
            ForceBootstrap = $true
        }
        if($VerbosePreference -eq 'Continue') { $providerBootstrapParams.add('verbose',$true)}
        if ($GalleryProxy) { $providerBootstrapParams.Add('Proxy',$GalleryProxy) }
        Write-Verbose "Installing NuGet Provider"
        $null = Install-PackageProvider @providerBootstrapParams
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    if (!(Get-Module -Listavailable PSDepend)) {
        Write-Verbose "BootStrapping PSDepend"
        Write-Verbose "Parameter $BuildOutput"
        $InstallPSDependParams = @{
            Name = 'PSDepend'
            AllowClobber = $true
            Confirm = $false
            Force = $true
            Scope = 'CurrentUser'
        }
        if($VerbosePreference -eq 'Continue') { $InstallPSDependParams.add('verbose',$true)}
        if ($GalleryRepository) { $InstallPSDependParams.Add('Repository',$GalleryRepository) }
        if ($GalleryProxy)      { $InstallPSDependParams.Add('Proxy',$GalleryProxy) }
        if ($GalleryCredential) { $InstallPSDependParams.Add('ProxyCredential',$GalleryCredential) }
        Install-Module @InstallPSDependParams
        # TEMP fix
        $PSDependPath=Split-Path -Parent ((Get-Module PSDepend -listAvailable).Path)
        Copy-Item .\.Build\Github.ps1 (Join-Path $PSDependPath 'PSDependScripts') -Force
    }

    Write-Verbose "Invoking PSDepend (download dependencies)"
    $PSDependParams = @{
        Force = $true
        Path = (Join-Path ($Pwd.Path) '.build/module.requirements.psd1')
    }
    if($PSBoundParameters.ContainsKey['Verbose']) { $PSDependParams.add('verbose',$PSBoundParameters['Verbose'])}
    $null=Invoke-PSDepend @PSDependParams
    # TEMP fix
    $ExportNUnitXMLPath=Split-Path -Parent ((Get-Module Export-NUnitXML -listAvailable).Path)
    Copy-Item .\.Build\Export-NUnitXML.psm1 $ExportNUnitXMLPath -Force
}

if ($InstallDependencies) {
    Write-Information "Installing dependencies... [this can take a moment]"
    $Params = @{}
    if($PSBoundParameters.ContainsKey['Verbose']) { $Params.add('verbose',$PSBoundParameters['Verbose'])}
    Install-Dependencies @Params    
    Write-Verbose "Dependency installation done"
    if (Get-ChildItem "Env:APPVEYOR*") {
        $Env:APPVEYOR_SAVE_CACHE_ON_ERROR='true'
    }
    # Exit the script
    Exit 0
}

if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    try {
        # @PSBoundParameters
        Invoke-Build $Tasks $MyInvocation.MyCommand.Path -Result 'Result'
    }
    finally {
        $BuildSuccess=$?
        if (($null -ne $Result) -and ($null -ne $Result.Tasks)) {
            if (-not $BuildSuccess) {
                "Build error report"
                $Result.Tasks | Format-Table Name, Error -AutoSize|out-string
            }
            "Build duration report"
            $Result.Tasks | Format-Table -AutoSize Name,@{
                Name = 'ScriptName'
                Expression = {$_.InvocationInfo.ScriptName}
            }, Elapsed
        }
        if (-not $BuildSuccess) {
            Throw 'Build FAILED'
        }
    }
    return    
}


<#
# Initialize Build specific variables
$InitializeBuildFile=Join-Path "$PSScriptRoot/.Build/Tasks/" "InitializeTasks.ps1"
if (Test-Path $InitializeBuildFile) {
    . $InitializeBuildFile
}
#>

# Loading Build Tasks defined in the .Build/Tasks folder
Get-ChildItem -Path "$PSScriptRoot/.Build/Tasks/" -Recurse -Include *.Task.ps1 -Verbose | Foreach-Object {
        Write-Verbose "Importing Task file $($_.BaseName)"
        . $_.FullName 
}

# Defining the Default task 'workflow' when invoked without -tasks parameter
task . Init, Build, Helpify, Test
task Init SetBuildHeader, ImportDependencies, SetVariables
task Build Copy, Compile, BuildModule, BuildManifest, SetVersion
task Helpify GenerateMarkdown, GenerateHelp
task PublishResults "?PublishTestResults","?PublishCodeCoverage"
# Don't fail build if Test Results publishing fails
task Test Build, ImportModule, Analyze, Pester, PublishResults, FailBuildOnPesterFail, FailBuildOnCodeCovFail

task TFS Clean, Build, PublishVersion, Helpify, Test
task Publish TFS, PublishModule
# Only show code coverage, don't fail in DevTest
task DevTest SetVariables, ImportDevModule, "?Analyze", PesterDev, "?FailBuildOnCodeCovFail", FailBuildOnPesterFail

# Define a dummy task when you don't want any task executed (e.g. Only load PSModulePath)
task Noop {}