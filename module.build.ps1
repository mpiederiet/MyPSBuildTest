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

    $TaskHeader = {
        param($Path)
        $FigletTask=Convertto-FigletFont -InputObject $Task.Name.replace('_',' ').ToUpper() -Font 'Big'
        $MaximumHeaderSize=($FigletTask -split "`n" | Measure-Object -Maximum length).Maximum
        ''
        '=' * $MaximumHeaderSize
        Write-Build Cyan $FigletTask
        Write-Build DarkGray  "$(Get-BuildSynopsis $Task)"
        '-' * $MaximumHeaderSize
        Write-Build DarkGray "  $Path"
        Write-Build DarkGray "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
        ''
    },

    $CodeCoverageThreshold = 80
)

Process {
    Write-Debug "$($MyInvocation.ScriptName): $($PSBoundParameters | out-string)"
    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
<#        if ($PSboundParameters.ContainsKey('Bootstrap')) {
            Write-Verbose "Dependencies already bootstrapped. Handing over to InvokeBuild."
            $null = $PSboundParameters.Remove('Bootstrap')
        }
#>
        Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
        return
    }


    # Download PowerFiglet PS module
    # Check whether there is a "latest" release
    <#
    try {
        $LatestRelease=invoke-webrequest 'https://api.github.com/repos/MischaBoender/PowerFIGlet/releases/latest'
    }
    catch [System.Net.WebException] {
        $LatestRelease=$_.Exception.Response
    }
    if ($latestRelease.StatusCode -eq 404) {
        # no non-prereleases found, try to find one from all releases and sort by tag
        try {
            $Releases=invoke-webrequest 'https://api.github.com/repos/MischaBoender/PowerFIGlet/releases'
        }
        catch [System.Net.WebException] {
            $Releases=$_.Exception.Response
        }
        if ($releases.statusCode -eq 200) {
            $LatestRelease=(($Releases.content|convertfrom-json)|Sort-Object tag_name -desc|Select-Object -first 1)
        } Else {
            $LatestRelease=$null
        }
    }

    if ($null -ne $LatestRelease) {
        # Download the module
        $FileName=$LatestRelease.assets.name
        Invoke-WebRequest $LatestRelease.assets.browser_download_url -OutFile $FileName
        $TargetPath=Join-path $Env:BHBuildOutput "Modules\$($FileName -replace '\.zip$','')"
        Expand-Archive -Path $FileName -DestinationPath $TargetPath
    }
    #>

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

    # Defining the task header for this Build Job
    if($TaskHeader) { Set-BuildHeader $TaskHeader }

    # Defining the Default task 'workflow' when invoked without -tasks parameter
    task . Build, Helpify, Test, UpdateSource
    task Build Copy, Compile, BuildModule, BuildManifest, SetVersion
    task Helpify GenerateMarkdown, GenerateHelp
    task Test Build, ImportModule, Analyze, Pester
    task Publish TFS, PublishModule
    task TFS CleanModule, Build, PublishVersion, Helpify, Test
    task DevTest ImportDevModule, Pester

    # Define a dummy task when you don't want any task executed (e.g. Only load PSModulePath)
    task Noop {}
}


begin {
    function Install-Dependencies {
        [CmdletBinding()]
        param()

        if (!(Get-PackageProvider -Name NuGet -ForceBootstrap)) {
            $providerBootstrapParams = @{
                Name = 'nuget'
                force = $true
                ForceBootstrap = $true
            }
            if($PSBoundParameters.ContainsKey('verbose')) { $providerBootstrapParams.add('verbose',$verbose)}
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
            if($PSBoundParameters.ContainsKey('verbose')) { $InstallPSDependParams.add('verbose',$verbose)}
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
            Path = "$PSScriptRoot/.build/module.Requirements.psd1"
        }
        if($PSBoundParameters.ContainsKey('verbose')) { $PSDependParams.add('verbose',$verbose)}
        $null=Invoke-PSDepend @PSDependParams
        # TEMP fix
        $ExportNUnitXMLPath=Split-Path -Parent ((Get-Module Export-NUnitXML -listAvailable).Path)
        Copy-Item .\.Build\Export-NUnitXML.psm1 $ExportNUnitXMLPath -Force
    }

    if (![io.path]::IsPathRooted($BuildOutput)) {
        $BuildOutput = Join-Path -Path $PSScriptRoot -ChildPath $BuildOutput
    }

    $Script:LocalModulePath=Join-Path $BuildOutput 'Modules'
    
    if ($InstallDependencies) {
        Write-Information "Installing dependencies... [this can take a moment]"
        $Params = @{}
        if ($PSboundParameters.ContainsKey('verbose')) {
            $Params.Add('verbose',$PSBoundParameters['verbose'])
        }
        Install-Dependencies @Params    
        Write-Verbose "Dependency installation done"

        # Exit the script, don't process the Process and End scriptblocks
        exit 0
    }

    Write-Verbose "Invoking PSDepend (importing modules)"
    $PSDependParams = @{
        Force = $true
        Path = "$PSScriptRoot/.build/module.requirements.psd1"
        Import = $true
    }
    if($PSBoundParameters.ContainsKey('verbose')) { $PSDependParams.add('verbose',$verbose)}
    $null=Invoke-PSDepend @PSDependParams
    
    if ($null -eq (Get-ChildItem 'Env:BH*')) {
        Write-Verbose "Setting Build Environment variables"
        Set-BuildEnvironment -BuildOutput $BuildOutput
    } else {
        Write-Verbose "Build Environment variables already set"
    }
}