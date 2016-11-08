#Requires -modules WebServicesPowerShellProxyBuilder

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
        $InstallerToBeIncluded,
        [Switch]$Force
    )

    $PackageDirectory = "$PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\tools"

    if ($InstallerToBeIncluded) {    
       Copy-Item -Path $InstallerToBeIncluded -Destination $PackageDirectory    
    }

    #&choco.exe pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey"
    
    choco pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey" $(if($Force){"--force"})

    if ($InstallerToBeIncluded) {
        Remove-Item -Path (Join-Path -Path $PackageDirectory -ChildPath (Split-Path -Path $InstallerToBeIncluded -Leaf))
    }
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

function New-TervisChocolateyPackageConfigPackage {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]$id,
        $version,
        $source,
        $installArguments,
        $packageParameters,
        [Switch]$forceX86,
        [Switch]$allowMultipleVersions,
        [Switch]$ignoreDependencies        
    )
    process {
        New-XMLElement -Name package -Attributes ($PSBoundParameters | ConvertFrom-PSBoundParameters)
    }
}

function New-TervisChocolateyPackageConfig {
    param (
        $PackageConfigPackages
    )
    New-XMLDocument -Version "1.0" -Encoding "utf-8" -InnerElements (
        New-XMLElement -Name packages -InnerElements (
            $PackageConfigPackages
        )
    ) 
}

function Install-TervisChocolatey {
    [CmdletBinding()]
    param (
        $ComputerName,
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Write-Verbose "Installing Chocolatey"
    Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        refreshenv
        choco feature enable -n allowEmptyChecksums
        choco source add -n=Tervis -s "\\$env:USERDNSDOMAIN\applications\chocolatey\"
        choco source list
    }
}

function Install-TervisChocolateyPackages {
    [CmdletBinding()]
    param (
        $ComputerName,
        $Credential = [System.Management.Automation.PSCredential]::Empty,
        $ChocolateyPackageGroupNames
    )
    $ChocolateyPackageGroups = $ChocolateyPackageGroupNames | Get-ChocolateyPackageGroup
    
    $ChocolateyPackagesIncludedMoreThanOnce = $ChocolateyPackageGroups.ChocolateyPackageConfigPackages | 
        group id | 
        where count -GT 1 | 
        select -ExpandProperty group

    if ($ChocolateyPackagesIncludedMoreThanOnce) {        
        Throw "There are chocolatey packages included more than once: $ChocolateyPackagesIncludedMoreThanOnce"
    }

    $ChocolateyPackageConfig = New-TervisChocolateyPackageConfig -PackageConfigPackages $ChocolateyPackageGroups.ChocolateyPackageConfigPackages

    Invoke-Command -ComputerName $ComputerName -Credential $Credential -ArgumentList $ChocolateyPackageConfig.OuterXml -ScriptBlock {
        param (
            $PackagConfigFileContent
        )
        $PackageConfigFile = "$env:USERPROFILE\PackageConfigFile.config"
        $PackagConfigFileContent | out-file $PackageConfigFile

        choco install $PackageConfigFile -y
    }
}

$ChocolateyPackageGroups = [PSCustomObject][Ordered] @{
    Name = "StandardOfficeEndpoint"
    ChocolateyPackageConfigPackages = @(
        (
            "CiscoJabber","googlechrome","firefox","autohotkey","greenshot","office365-2016-deployment-tool","adobereader" | 
            New-TervisChocolateyPackageConfigPackage
        ) +
        (New-TervisChocolateyPackageConfigPackage -id jre8 -packageParameters "/exclude:64")
    )
},
[PSCustomObject][Ordered] @{
    Name = "ContactCenter"
    ChocolateyPackageConfigPackages = @(
        (New-TervisChocolateyPackageConfigPackage -id CiscoAgentDesktop)
    )
},
[PSCustomObject][Ordered] @{
    Name = "IT"
    ChocolateyPackageConfigPackages = @(
        (
            "putty","notepadplusplus","rufus","7zip","vlc","sysinternals","skype","filezilla","wireshark","evernote","fiddler4","nmap","everything","pester","rdm","windirstat","speedcrunch","gimp","git","todoist" | 
            New-TervisChocolateyPackageConfigPackage
        )
    )
}

function Get-ChocolateyPackageGroup {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$Name
    )
    process {
        $ChocolateyPackageGroups | where Name -eq $Name
    }
}
