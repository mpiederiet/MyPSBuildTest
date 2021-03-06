$Script:ModuleRoot = $Env:BHProjectPath
$Script:ModuleName = $Env:BHProjectName

$Script:SourceRoot = Join-Path -Path $ModuleRoot -ChildPath $ModuleName

Describe "Public commands have Pester tests" -Tag 'Build','BeforePublish' {
    $commands = Get-Command -Module $ModuleName

    foreach ($command in $commands.Name)
    {
        $script:file = Get-ChildItem -Path "$ModuleRoot\Tests" -Include "$command.Tests.ps1" -Recurse
        It "Should have a Pester test for [$command]" {
            $file.FullName | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Module import" -Tag 'Build' {
    It "Should import without throwing" {
        {Import-Module "$Source\$ModuleName.psd1" -Force} | Should -Not -Throw
    }
    It "Should generate a module object" {
        {{Import-Module "$Source\$ModuleName.psd1" -Force -PassThru} -is [System.Management.Automation.PSModuleInfo]} | Should -Be $True
    }
}

Describe "Module import" -Tag 'BeforePublish' {
    It "Should import without throwing" {
        {Import-Module $ManifestPath -Force} | Should -Not -Throw
    }
    It "Should generate a module object" {
        {{Import-Module $ManifestPath -Force -PassThru} -is [System.Management.Automation.PSModuleInfo]} | Should -Be $True
    }
}