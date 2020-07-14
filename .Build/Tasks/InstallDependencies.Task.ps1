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
        Path = (Join-Path $BuildRoot '.build/module.requirements.psd1')
    }
    if($VerbosePreference -eq 'Continue') { $PSDependParams.add('verbose',$true)}
    $null=Invoke-PSDepend @PSDependParams
    # TEMP fix
    $ExportNUnitXMLPath=Split-Path -Parent ((Get-Module Export-NUnitXML -listAvailable).Path)
    Copy-Item .\.Build\Export-NUnitXML.psm1 $ExportNUnitXMLPath -Force
}

task InstallDependencies {
    Write-Information "Installing dependencies... [this can take a moment]"
    $Params = @{}
    if($VerbosePreference -eq 'Continue') { $Params.add('verbose',$true)}
    Install-Dependencies @Params    
    Write-Verbose "Dependency installation done"

    Write-Verbose "Invoking PSDepend (importing modules)"
    $PSDependParams = @{
        Force = $true
        Path = (Join-Path $BuildRoot '.build/module.requirements.psd1')
        Import = $true
    }
    if($VerbosePreference -eq 'Continue') { $PSDependParams.add('verbose',$true)}
    $null=Invoke-PSDepend @PSDependParams
}