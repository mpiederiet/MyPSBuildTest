task PublishVersion {
    [version] $sourceVersion = (Get-Metadata -Path $manifestPath -PropertyName 'ModuleVersion')

    switch ($Env:BHBuildSystem) {
        'AppVeyor' {
            # https://www.appveyor.com/docs/build-worker-api/#update-build-details
            Update-AppVeyorBuild -Version $SourceVersion
            break
        }
        'Azure Pipelines' {
            "##vso[build.updatebuildnumber]$sourceVersion"
            break
        }
        default {
            <#
            'GitLab CI'
            'Jenkins'
            'Teamcity'
            'Bamboo'
            'GoCD'
            'Travis CI'
            'GitHub Actions'
            'Unknown'
            #>
    
            Write-Warning "Unknown build system [$_]. Version number not updated."
        }
    }
}
