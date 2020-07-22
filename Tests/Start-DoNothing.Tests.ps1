Describe "Function: Start-DoNothing" -Tag 'Build','Dev' {
    It "Does not throw" {
        {Start-DoNothing} | Should -Not -Throw
    }

    It "Executes a script and gives results" {
        Start-DoNothing | Should -Be 'nothing'
    }
}
