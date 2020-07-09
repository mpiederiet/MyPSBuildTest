function Start-DoNothing {
if ((Get-Process|sort|Out-null) -eq $null) {
    # Do nothing
    $Global:Something='nothing'
   }
}