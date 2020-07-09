Describe "Function: Start-DoNothing" -Tag Build {
    It "Does not throw" {
        {Start-DoNothing} | Should -Not -Throw
    }

    It "Executes a script and gives results" {
        Start-DoNothing
        $Global:Something | Should -Be 'nothing'
    }
}
