@{
    # Set up a mini virtual environment...
    PSDependOptions = @{
        AddToPath = $True
        Target    = '.\BuildOutput\Modules'
    }

    BuildHelpers        = 'latest'
    InvokeBuild         = 'latest'
    Pester              = 'latest'
    PSScriptAnalyzer    = 'latest'
    PlatyPS             = 'latest'
    PSDeploy            = 'latest'
    'MischaBoender/PowerFIGlet' = @{
        Version        = 'latest'
        DependencyType = 'GitHub'
        Parameters     = @{
            ExtractPath = 'release/PowerFIGlet'
        }
    }
    'MathieuBuisson/PowerShell-DevOps' = @{
        Name           = 'Export-NUnitXML'
        Version        = 'master'
        DependencyType = 'GitHub'
        Parameters     = @{
            ExtractPath = 'Export-NUnitXML\Export-NUnitXML.psm1'
        }
    }
}