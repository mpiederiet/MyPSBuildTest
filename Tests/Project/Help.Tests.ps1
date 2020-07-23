$Script:ModuleRoot = $Env:BHProjectPath
$Script:ModuleName = $Env:BHProjectName

Describe "Public commands have comment-based or external help" -Tag 'Build','BeforePublish' {
    $functions = Get-Command -Module $ModuleName
    $help = foreach ($function in $functions) {
        Get-Help -Name $function.Name
    }

    foreach ($script:node in $help)
    {
        Context ("$($node.category) $($node.Name)") {
            It "Should have a Description and Synopsis" {
                $Node.Description |  Should -Not -BeNullOrEmpty
                $Node.Synopsis |  Should -Not -BeNullOrEmpty
            }

            It "Should have an Example"  {
                $node.Examples | Should -Not -BeNullOrEmpty
            }

            It "Should have its name in the Example" {
                $node.Examples | Out-String | Should -Match ($node.Name)
            }

            foreach ($parameter in $node.Parameters.Parameter)
            {
                if ($parameter -notmatch 'WhatIf|Confirm')
                {
                    It "Should have a Description for Parameter [$($parameter.Name)]" {
                        $parameter.Description.Text | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }
}
