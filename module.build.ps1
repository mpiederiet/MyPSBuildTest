[cmdletBinding()]
Param (
    [Parameter(Position=0)]
    $Tasks,

    [switch]
    $InstallDependencies,

    [String]
    $BuildOutput = "BuildOutput",

    [String[]]
    $GalleryRepository,

    [Uri]
    $GalleryProxy,

    $CodeCoverageThreshold = 80
)
Write-Debug "$($MyInvocation.ScriptName): $($PSBoundParameters | out-string)"
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    try {
        Invoke-Build $Tasks $MyInvocation.MyCommand.Path -Result 'Result' @PSBoundParameters
    }
    finally {
        $BuildSuccess=$?
        if (($null -ne $Result) -and ($null -ne $Result.Tasks)) {
            "Build error report"
            $Result.Tasks | Format-Table Name, Error -AutoSize|out-string
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

# Initialize Build specific variables
$InitializeBuildFile=Join-Path "$PSScriptRoot/.Build/Tasks/" "InitializeTasks.ps1"
if (Test-Path $InitializeBuildFile) {
    . $InitializeBuildFile
}

# Loading Build Tasks defined in the .build/ folder
Get-ChildItem -Path "$PSScriptRoot/.Build/Tasks/" -Recurse -Include *.Task.ps1 -Verbose | Foreach-Object {
        Write-Verbose "Importing Task file $($_.BaseName)"
        . $_.FullName 
}

# Defining the Default task 'workflow' when invoked without -tasks parameter
task . Init, Build, Helpify, Test
task Init SetBuildHeader, InstallDependencies, SetVariables
task Build Copy, Compile, BuildModule, BuildManifest, SetVersion
task Helpify GenerateMarkdown, GenerateHelp
task Test Build, ImportModule, Analyze, Pester

task TFS CleanModule, Build, PublishVersion, Helpify, Test
task Publish TFS, PublishModule
task DevTest ImportDevModule, Pester

# Define a dummy task when you don't want any task executed (e.g. Only load PSModulePath)
task Noop {}