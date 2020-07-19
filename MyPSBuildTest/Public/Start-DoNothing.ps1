function Start-DoNothing {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if ($null -eq (Get-Process|Sort-Object|Out-null)) {
        # Do nothing
        #$Script:Something='nothing'
        Start-Sleep -Milliseconds 1
    }
}