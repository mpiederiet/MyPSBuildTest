$Script:ModuleRoot = $Env:BHProjectPath
$Script:ModuleName = $Env:BHProjectName

$Script:SourceRoot = Join-Path -Path $ModuleRoot -ChildPath $ModuleName

Describe "Public commands have Pester tests" -Tag 'Build' {
    $commands = Get-Command -Module $ModuleName

    foreach ($command in $commands.Name)
    {
        $script:file = Get-ChildItem -Path "$ModuleRoot\Tests" -Include "$command.Tests.ps1" -Recurse
        It "Should have a Pester test for [$command]" {
            $file.FullName | Should -Not -BeNullOrEmpty
        }
    }
}
