$Script:ModuleRoot = $Env:BHProjectPath
$Script:ModuleName = $Env:BHProjectName

$Script:SourceRoot = Join-Path -Path $ModuleRoot -ChildPath $ModuleName

Describe "Module import" -Tag 'Dev' {
    It "Should import without throwing" {
        {Import-Module "$Source\$ModuleName.psd1" -Force} | Should -Not -Throw
    }
    It "Should generate a module object" {
        {Import-Module "$Source\$ModuleName.psd1" -Force -PassThru}| Should -Not -BeNullOrEmpty
    }
}