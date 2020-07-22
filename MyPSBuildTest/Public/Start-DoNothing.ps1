function Start-DoNothing {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if ($null -eq (Get-Process|Sort-Object|Out-null)) {
        # Do nothing
        if($PSCmdlet.ShouldProcess('No process')) {
            Start-Sleep -Milliseconds 1
        }
    }
    Return 'nothing'
}