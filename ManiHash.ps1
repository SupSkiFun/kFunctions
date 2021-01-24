$mhash = @{
    RootModule = 'kFunctions.psm1'
    ModuleVersion = '1.1.1.1'
    Author = 'Joe Acosta'
    CompanyName = 'SupSkiFun'
    Copyright = '(c) 2021 Joe Acosta. All rights reserved.'
    Description = 'PowerShell 7 Advanced Functions for Kubernetes.'
    Path = 'C:\Users\ja0310\scripts\AdvFunc\kFunctions\1.1.1.1\kFunctions.psd1'
    FunctionsToExport = 'Get-K8sAPIInfo'
    ProjectUri = 'https://github.com/SupSkiFun/kFunctions'
    ReleaseNotes = 'Read Examples and Notes for function use.  Written for PowerShell 7.'
    FileList = @(
        'kFunctions.psd1'
        'kFunctions.psm1'
        'kClass.psm1'
    )
    Tags = @(
        'API'
        'K3s'
        'K8s'
        'Kubernetes'
    )
}
$mhash