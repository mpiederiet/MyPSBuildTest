task ImportDependencies {

    Write-Verbose "Invoking PSDepend (importing modules)"
    $PSDependParams = @{
        Force = $true
        Path = (Join-Path $BuildRoot '.build/module.requirements.psd1')
        Import = $true
    }
    if($VerbosePreference -eq 'Continue') { $PSDependParams.add('verbose',$true)}
    $null=Invoke-PSDepend @PSDependParams
}