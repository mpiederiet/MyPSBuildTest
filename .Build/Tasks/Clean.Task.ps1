task Clean {
    if (Test-Path $Destination) {
        "Cleaning Output files in [$Destination]..."
        $null = Get-ChildItem -Path $Destination -File -Recurse |
            Remove-Item -Force -ErrorAction 'Ignore'

        "Cleaning Output directories in [$Destination]..."
        $null = Get-ChildItem -Path $Destination -Directory -Recurse |
            Remove-Item -Recurse -Force -ErrorAction 'Ignore'
    }
}