function New-TervisChocolateyPackage {
    param (
        $PowerShellModulesPath = ($ENV:PSModulepath -split ";")[0],
        [Parameter(Mandatory)]$PackageName,
        [Parameter(Mandatory)]$URL,
        [Parameter(Mandatory)]$Version
    )

    choco new $PackageName --outputdirectory "$PowerShellModulesPath\chocolateyautomaticpackages\Static" maintainername="TervisIT" maintainerrepo="https://github.com/Tervis-Tumbler/chocolateyautomaticpackages/tree/master/Static/$PackageName" url="$URL" packageversion="$Version"
    
}

function Invoke-TervisChocolateyPackPackage {
    param (
        $PowerShellModulesPath = ($ENV:PSModulepath -split ";")[0],
        $PackageName
    )
    #&choco.exe pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\tervis.prv\applications\Chocolatey"
    choco pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\tervis.prv\applications\Chocolatey"
}

#New-TervisChocolateyPackage -PackageName iVMS-4200 -URL "http://oversea-download.hikvision.com/uploadfile/USA/Software/iVMS-4200v2.5.0.5Download_Package_contains_Lite_&_Full_versions.zip"

function Install-TervisChocolateyPackageInstall {
    param (
        [Parameter(Mandatory)]$PackageName
    )

    choco install $PackageName --source="\\tervis.prv\applications\Chocolatey" -y --allowemptychecksum
}