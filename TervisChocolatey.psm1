function New-TervisChocolateyPackage {
    param (
        $PowerShellModulesPath = ($ENV:PSModulepath -split ";")[0],
        [Parameter(Mandatory)]$PackageName,
        [Parameter(Mandatory)]$Version,
        $URL
    )

    choco new $PackageName --outputdirectory "$PowerShellModulesPath\chocolateyautomaticpackages\Static" maintainername="TervisIT" maintainerrepo="https://github.com/Tervis-Tumbler/chocolateyautomaticpackages/tree/master/Static/$PackageName" url="$URL" packageversion="$Version"
    
}

function Invoke-TervisChocolateyPackPackage {
    param (
        $PowerShellModulesPath = ($ENV:PSModulepath -split ";")[0],
        $PackageName,
        [Switch]$Force
    )

    #&choco.exe pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey"
    choco pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey" $(if($Force){"--force"})
}

#New-TervisChocolateyPackage -PackageName iVMS-4200 -URL "http://oversea-download.hikvision.com/uploadfile/USA/Software/iVMS-4200v2.5.0.5Download_Package_contains_Lite_&_Full_versions.zip" -Version "2.5.0.5" -PowerShellModulesPath C:\test

function Install-TervisChocolateyPackageInstall {
    param (
        [Parameter(Mandatory)]$PackageName,
        [Switch]$Force
    )

    choco install $PackageName --source="\\$env:USERDNSDOMAIN\applications\Chocolatey" -y --allowemptychecksum $(if($Force){"--force"})
}

function Uninstall-TervisChocolateyPackageInstall {
    param (
        [Parameter(Mandatory)]$PackageName,
        [Switch]$Force
    )
    
    choco uninstall $PackageName -y $(if($Force){"--force"})
}