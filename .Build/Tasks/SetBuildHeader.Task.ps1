task SetBuildHeader {
    # Defining the task header for this Build Job

    $TaskHeader = {
        param($Path)
        if (Get-Module PowerFIGLet -ErrorAction 'SilentlyContinue') {
            $TaskText=Convertto-FigletFont -InputObject $Task.Name.replace('_',' ').ToLower() -Font 'Ogre'
            $MaximumHeaderSize=($TaskText -split "`n" | Measure-Object -Maximum length).Maximum
        } Else {
            $TaskText='    '+$Task.Name.ToUpper()+'    '
            $MaximumHeaderSize=$TaskText.Length+8
        }
        ''
        '=' * $MaximumHeaderSize
        Write-Build Cyan $TaskText
        Write-Build DarkGray  "$(Get-BuildSynopsis $Task)"
        '-' * $MaximumHeaderSize
        Write-Build DarkGray "  $Path"
        Write-Build DarkGray "  $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
        ''
    }
    Set-BuildHeader $TaskHeader
}