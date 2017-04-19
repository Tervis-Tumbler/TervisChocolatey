#Requires -modules WebServicesPowerShellProxyBuilder,PasswordstatePowershell

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
        $PackageDirectory = "$(($ENV:PSModulepath -split ";")[0])\chocolateyautomaticpackages\Static\$PackageName",
        $PackageName,
        $InstallerToBeIncluded,
        [Switch]$Force
    )


    if ($InstallerToBeIncluded) {        
        Copy-Item -Path $InstallerToBeIncluded -Destination "$PackageDirectory\tools"
    }

    #&choco.exe pack $PowerShellModulesPath\chocolateyautomaticpackages\Static\$PackageName\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey"
    
    choco pack $PackageDirectory\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey" $(if($Force){"--force"})

    if ($InstallerToBeIncluded) {
        Remove-Item -Path (Join-Path -Path $PackageDirectory -ChildPath (Split-Path -Path $InstallerToBeIncluded -Leaf))
    }
}

#New-TervisChocolateyPackage -PackageName iVMS-4200 -URL "http://oversea-download.hikvision.com/uploadfile/USA/Software/iVMS-4200v2.5.0.5Download_Package_contains_Lite_&_Full_versions.zip" -Version "2.5.0.5" -PowerShellModulesPath C:\test

function Install-TervisChocolateyPackageInstall {
    param (
        [Parameter(Mandatory)]$PackageName,
        $Source = "\\$env:USERDNSDOMAIN\applications\Chocolatey",
        [Switch]$Force
    )

    choco install $PackageName --source=$Source -y --allowemptychecksum $(if($Force){"--force"})
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
        try { choco } catch {
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
    }
    Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
        $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

        $locations | ForEach-Object {   
            $k = Get-Item $_
            $k.GetValueNames() | ForEach-Object {
                $name  = $_
                $value = $k.GetValue($_)
                Set-Item -Path Env:\$name -Value $value
            }
        }

        choco feature enable -n allowEmptyChecksums
        choco source add -n=Tervis -s "\\$env:USERDNSDOMAIN\applications\chocolatey\"
        choco source list
    }
}

function Install-TervisChocolateyPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$ComputerName,
        [Parameter(Mandatory)]$PackageName,
        $Version,
        $PackageParameters,
        $Source,
        [switch]$Force
    )
    
    $ChocolateyInstallString = "choco install $PackageName -y "
    if ($Version) {
        $ChocolateyInstallString += "--version $Version "
    }
    if ($PackageParameters) {
        $ChocolateyInstallString += "-packageParameters `"$PackageParameters`" "
    }
    if ($Source) {
        $ChocolateyInstallString += "--source `"$Source`" "
    }
    if ($Force) {
        $ChocolateyInstallString += "-f"
    }

    $ChocolateyInstallScriptBlock = [ScriptBlock]::Create($ChocolateyInstallString)

    Write-Verbose "Executing `"$ChocolateyInstallString`" on $ComputerName"
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $ChocolateyInstallScriptBlock
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
        $locations = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

        $locations | ForEach-Object {   
            $k = Get-Item $_
            $k.GetValueNames() | ForEach-Object {
                $name  = $_
                $value = $k.GetValue($_)
                Set-Item -Path Env:\$name -Value $value
            }
        }

        $PackageConfigFile = "$env:USERPROFILE\PackageConfigFile.config"
        $PackagConfigFileContent | out-file $PackageConfigFile

        choco install $PackageConfigFile -y
    }
}

$ChocolateyPackageGroups = [PSCustomObject][Ordered] @{
    Name = "StandardOfficeEndpoint"
    ChocolateyPackageConfigPackages = @(
        (
@"
CiscoJabber
CiscoAnyConnect
camunda-modeler
googlechrome
firefox
autohotkey
greenshot
office365-2016-deployment-tool
adobereader
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) +
        @(New-TervisChocolateyPackageConfigPackage -id jre8 -packageParameters "/exclude:64")
    )
},
[PSCustomObject][Ordered] @{
    Name = "ContactCenter"
    ChocolateyPackageConfigPackages =  @(
@"
paint.net
CiscoAgentDesktop
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    )
},
[PSCustomObject][Ordered] @{
    Name = "IT"
    ChocolateyPackageConfigPackages = @(
        (
@"
7zip
baretail
evernote
everything
fiddler4
filezilla
gimp
github
imgburn
macrocreator
nmap
notepadplusplus
paint.net
pester
putty
rdm
rsat
rufus
skype
speedcrunch
sql-server-management-studio
sumatrapdf
sysinternals
todoist
vlc
windirstat
winmerge
wireshark
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "IT Chris"
    ChocolateyPackageConfigPackages = @(
        (
@"
anki
eclipse
hmailserver
ilspy
keepass
kindle
pal
scansnapmanager
spf13-vim
testdisk-photorec
usbview
ussf
windbg
todoist-outlook
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "Kjono"
    ChocolateyPackageConfigPackages = @(
        (
@"
eclipse
keepass
windbg
windirstat
winmerge
sysinternals
sql-server-management-studio
skype
putty
rsat
nmap
github
filezilla
7zip
evernote
fiddler4
greenshot
office365-2016-deployment-tool
CiscoJabber
CiscoAnyConnect
googlechrome
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "KafkaBroker"
    ChocolateyPackageConfigPackages = @(New-TervisChocolateyPackageConfigPackage -id kafka -version 0.10.2.0)
},
[PSCustomObject][Ordered] @{
    Name = "BartenderCommander"
    ChocolateyPackageConfigPackages =  @(
        (New-TervisChocolateyPackageConfigPackage -id sqlanywhereclient -version 12.0.1),
        (New-TervisChocolateyPackageConfigPackage -id bartender -version 10.0.2868 -packageParameters $(
            "Edition=EA Remove=Librarian,LicenseServer,PrinterMaestro,BatchMaker,HistoryExplorer PKC=$(
                (Get-PasswordstateCredential -PasswordID 4096 -AsPlainText).Password
            )"
        ))
    )
},
[PSCustomObject][Ordered] @{
    Name = "BartenderLicenseServer"
    ChocolateyPackageConfigPackages =  @(        
        (New-TervisChocolateyPackageConfigPackage -id bartender -version 10.0.2868 -packageParameters $(
            "Edition=EA Remove=Librarian,PrinterMaestro,BatchMaker,HistoryExplorer AddLocal=LicenseServer PKC=$(
                (Get-PasswordstateCredential -PasswordID 4096 -AsPlainText).Password
            ) /L*v `"C:\ProgramData\Seagull\install.log`""
        ))
    )
},
[PSCustomObject][Ordered] @{
    Name = "Progistics"
    ChocolateyPackageConfigPackages =  @(
        (New-TervisChocolateyPackageConfigPackage -id sqlanywhereclient -version 12.0.1)
    )
},
[PSCustomObject][Ordered] @{
    Name = "WCSJavaApplication"
    ChocolateyPackageConfigPackages =  @(
@"
vcredist2010
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) + @(
        (New-TervisChocolateyPackageConfigPackage -id sqlanywhereclient -version 12.0.1),
        (New-TervisChocolateyPackageConfigPackage -id jre8)
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
