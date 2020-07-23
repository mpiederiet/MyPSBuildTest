function Start-DoNothing {
<#
.SYNOPSIS
Do nothing

.DESCRIPTION
What can I say, it just does nothing

.EXAMPLE
Start-DoNothing
# Displays 'nothing'

.NOTES
Don't expect this to do anything
#>
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