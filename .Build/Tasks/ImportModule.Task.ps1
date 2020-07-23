# Imports the "wrapper" module so it can be tested
task ImportModule {
    ImportModule -Path "$Source\$ModuleName.psd1" -Force
}