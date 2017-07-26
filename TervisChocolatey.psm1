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
    
    choco pack $PackageDirectory\$PackageName.nuspec --outputdirectory "\\$env:USERDNSDOMAIN\applications\Chocolatey" $(if($Force){"--force"})

    if ($InstallerToBeIncluded) {
        Remove-Item -Path (Join-Path -Path $PackageDirectory -ChildPath (Split-Path -Path $InstallerToBeIncluded -Leaf))
    }
}

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
            cmd /c "@powershell -NoProfile -ExecutionPolicy Bypass -Command `"iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`" && SET `"PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin`""
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

function Uninstall-TervisChocolateyPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$ComputerName,
        [Parameter(Mandatory)]$PackageName,
        [switch]$Force
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        choco uninstall $Using:PackageName -y $(if($Using:Force){"--force"})
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
        throw "There are chocolatey packages included more than once: $($ChocolateyPackagesIncludedMoreThanOnce.id)"
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

function Get-TervisChocholateyFileShareRepositoryPrincipalsAllowedToDelegateToAccount {
    $ADDomain = Get-ADDomain
    Get-DfsnFolderTarget -Path \\$($ADDomain.DNSRoot)\Applications\Chocolatey |
    Select -ExpandProperty TargetPath |
    ForEach-Object { ([URI]$_).Host.Split(".") | select -First 1 } |
    Get-ADComputer -Properties PrincipalsAllowedToDelegateToAccount
}

function Set-TervisChocholateyFileShareRepositoryHostsPrincipalsAllowedToDelegateToAccount {
    $ADDomain = Get-ADDomain
    Get-DfsnFolderTarget -Path \\$($ADDomain.DNSRoot)\Applications\Chocolatey |
    Select -ExpandProperty TargetPath |
    ForEach-Object { ([URI]$_).Host.Split(".") | select -First 1 } |
    Set-ADComputer -PrincipalsAllowedToDelegateToAccount Privilege_PrincipalsAllowedToDelegateToAccount
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
    ChocolateyPackageConfigPackages = @(New-TervisChocolateyPackageConfigPackage -id kafka)
},
[PSCustomObject][Ordered] @{
    Name = "BartenderCommander"
    ChocolateyPackageConfigPackages =  @(
        (New-TervisChocolateyPackageConfigPackage -id sqlanywhereclient -version 12.0.1),
        (New-TervisChocolateyPackageConfigPackage -id bartender -version 10.0.2868.1 -packageParameters $(
            "Edition=EA Remove=Librarian,LicenseServer,PrinterMaestro,BatchMaker,HistoryExplorer PKC=$(
                (Get-PasswordstateCredential -PasswordID 4096 -AsPlainText).Password
            )"
        ))
    )
},
[PSCustomObject][Ordered] @{
    Name = "BartenderIntegrationService"
    ChocolateyPackageConfigPackages =  @(
        (New-TervisChocolateyPackageConfigPackage -id sqlanywhereclient -version 12.0.1),
        (New-TervisChocolateyPackageConfigPackage -id bartender -version 11.0.4.3127 -packageParameters $(
            "Edition=EA ADDLOCAL=Bartender REMOVE=Librarian,HistoryExplorer,BatchMaker,PrintStation,PrinterMaestro,ReprintConsole PKC=$(
                (Get-PasswordstateCredential -PasswordID 4096 -AsPlainText).Password
            )"
        ))
    )
},
[PSCustomObject][Ordered] @{
    Name = "BartenderLicenseServer"
    ChocolateyPackageConfigPackages =  @(        
        (New-TervisChocolateyPackageConfigPackage -id bartender -version 10.0.2868.1 -packageParameters $(
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
procexp
vcredist2010
7zip
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) + @(
        (New-TervisChocolateyPackageConfigPackage -id sqlanywhereclient -version 12.0.1),
        (New-TervisChocolateyPackageConfigPackage -id jre8 -packageParameters "/exclude:64" )
    )
},
[PSCustomObject][Ordered] @{
    Name = "Phishing"
    ChocolateyPackageConfigPackages = @(
        (
@"
dotnetcore-sdk
nssm
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "RemoteWebBrowserApp"
    ChocolateyPackageConfigPackages = @(
        (
@"
googlechrome
firefox
adobereader
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "StoresRemoteDesktop"
    ChocolateyPackageConfigPackages = @(
        (
@"
googlechrome
firefox
adobereader
Office2016VL
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "ScheduledTasks"
    ChocolateyPackageConfigPackages = @(
        (
@"
msonline-signin-assistant
azure-ad-powershell-module
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "OracleDBA Remote Desktop"
    ChocolateyPackageConfigPackages =  @(
@"
WinSCP
Putty
googlechrome
firefox
DotNet-4.6.2
Office2016VL
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    )
},
[PSCustomObject][Ordered] @{
    Name = "WCSRemoteApp"
    ChocolateyPackageConfigPackages =  @(
        @(New-TervisChocolateyPackageConfigPackage -id jre8 -packageParameters "/exclude:64")
    )
},
[PSCustomObject][Ordered] @{
    Name = "DataLoadClassic"
    ChocolateyPackageConfigPackages =  @(
        @(New-TervisChocolateyPackageConfigPackage -id javaruntime -version 7.0.60)
    )
},
[PSCustomObject][Ordered] @{
    Name = "WindowsApps"
    ChocolateyPackageConfigPackages =  @(
@"
googlechrome
firefox
Office2016VL
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    )
},
[PSCustomObject][Ordered] @{
    Name = "EBSRemoteApp"
    ChocolateyPackageConfigPackages =  @(
@"
Office2010VL
FoxitReader
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    ) + (
        @(
            (New-TervisChocolateyPackageConfigPackage -id javaruntime -version 7.0.60),
            (New-TervisChocolateyPackageConfigPackage -id firefox -version 24.0),
            (New-TervisChocolateyPackageConfigPackage -id ghostscript.app -version 9.20),
            (New-TervisChocolateyPackageConfigPackage -id gimp -version 2.8.20)
        )
    )
}


function Get-ChocolateyPackageGroup {
    param (
        [Parameter(ValueFromPipeline)]$Name
    )
    process {
        $Result = $ChocolateyPackageGroups | where Name -eq $Name
        if ($Result) {$Result} else {
            Write-Warning "No Chocolatey package group defined for $Name"
        }
    }
}

function New-ChocolateyPackageFromDiskImage {
    param (
        [Parameter(Mandatory)]$PackageName,
        [Parameter(Mandatory)]$PathToDiskImage,
        [Parameter(Mandatory)]$Destination,
        [hashtable]$TemplateVariables
    )    
    
    $TemporaryWorkingDirectory = Join-Path -Path $env:TEMP -ChildPath "$($PackageName)_PackageFiles"
    if (Test-Path -Path $TemporaryWorkingDirectory) {
        Remove-Item -Path $TemporaryWorkingDirectory -Recurse -Force
    }
    New-Item -Path $env:TEMP -Name "$($PackageName)_PackageFiles" -ItemType Directory -Force | Out-Null
    New-Item -Path $TemporaryWorkingDirectory -Name tools -ItemType Directory | Out-Null
    New-Item -Path $TemporaryWorkingDirectory\tools -Name SetupFiles -ItemType Directory | Out-Null
    
    if ($TemplateVariables) {
        Invoke-ProcessTemplatePath `
            -Path (Join-Path -Path $PSScriptRoot -ChildPath "Templates\$PackageName") `
            -DestinationPath $TemporaryWorkingDirectory `
            -TemplateVariables $TemplateVariables
    }

    $MountedDiskImage = Mount-DiskImage -ImagePath $PathToDiskImage -PassThru
    $MountedDiskImageRoot = $MountedDiskImage | Get-DriveLetterPathFromDiskImage
    $SetupFilesSource = Join-Path -Path $MountedDiskImageRoot -ChildPath "*"
    Copy-Item -Path $SetupFilesSource -Destination $TemporaryWorkingDirectory\tools\SetupFiles -Recurse 
    Dismount-DiskImage -InputObject $MountedDiskImage
    $ExesToIgnore = Get-ChildItem -Path $TemporaryWorkingDirectory\tools\SetupFiles -Recurse -Filter *.exe
    foreach ($File in $EXEsToIgnore) {
        New-Item -Path "$($File.FullName).ignore" -ItemType File | Out-Null
    }

    choco pack "$TemporaryWorkingDirectory\$($PackageName).nuspec" --outputdirectory $Destination --force

    Remove-Item -Path $TemporaryWorkingDirectory -Recurse -Force    
}

function New-Office2016ChocolateyPackageFromDiskImage {
    param (
        [Parameter(Mandatory)]$PathToDiskImage,
        [Parameter(Mandatory)]$Destination,
        [Parameter(Mandatory)]$Version,
        $CompanyName = ""
    )      
    $PackageName = "Office2016VL"
    $TemplateVariables = @{
        Version = $Version
        CompanyName = $CompanyName
    }

    New-ChocolateyPackageFromDiskImage -PackageName $PackageName -PathToDiskImage $PathToDiskImage -Destination $Destination -TemplateVariables $TemplateVariables   
}

function New-Office2010ChocolateyPackageFromDiskImage {
    param (
        [Parameter(Mandatory)]$PathToDiskImage,
        [Parameter(Mandatory)]$Destination,
        [Parameter(Mandatory)]$Version,
        $CompanyName = ""
    )      
    $PackageName = "Office2010VL"
    $TemplateVariables = @{
        Version = $Version
        CompanyName = $CompanyName
    }

    New-ChocolateyPackageFromDiskImage -PackageName $PackageName -PathToDiskImage $PathToDiskImage -Destination $Destination -TemplateVariables $TemplateVariables   
}

function New-SQLServer2014SP2ChocolateyPackageFromDiskImage {
    param (
        [Parameter(Mandatory)]$PathToDiskImage,
        [Parameter(Mandatory)]$Destination,
        [Parameter(Mandatory)]$Version,
        $CompanyName = ""
    )      
    $PackageName = "SQLServer2016SP2"
    $TemplateVariables = @{
        Version = $Version
        CompanyName = $CompanyName
    }

    New-ChocolateyPackageFromDiskImage -PackageName $PackageName -PathToDiskImage $PathToDiskImage -Destination $Destination -TemplateVariables $TemplateVariables   
}

#function New-SQLServer2014SP2ChocolateyPackageFromDiskImage {
#    param (
#        [Parameter(Mandatory)]$PathToDiskImage,
#        [Parameter(Mandatory)]$Destination,
#        [Parameter(Mandatory)]$Version,
#        $CompanyName = ""
#    )    
#    
#    $TemporaryWorkingDirectory = Join-Path -Path $env:TEMP -ChildPath "SQL Server 2014 with SP2"
#    if (Test-Path -Path $TemporaryWorkingDirectory) {
#        Remove-Item -Path $TemporaryWorkingDirectory -Recurse -Force
#    }
#    New-Item -Path $env:TEMP -Name "SQLServer2014SP2_PackageFiles" -ItemType Directory -Force | Out-Null
#    New-Item -Path $TemporaryWorkingDirectory -Name tools -ItemType Directory | Out-Null
#    New-Item -Path $TemporaryWorkingDirectory\tools -Name SetupFiles -ItemType Directory | Out-Null
#    
#    $TemplateVariables = @{
#        Version = $Version
#        CompanyName = $CompanyName
#    }
#    Invoke-ProcessTemplatePath `
#        -Path (Join-Path -Path $PSScriptRoot -ChildPath "Templates\SQLServer2014SP2") `
#        -DestinationPath $TemporaryWorkingDirectory `
#        -TemplateVariables $TemplateVariables
#
#    $MountedDiskImage = Mount-DiskImage -ImagePath $PathToDiskImage -PassThru
#    $MountedDiskImageRoot = $MountedDiskImage | Get-DriveLetterPathFromDiskImage
#    Copy-Item -Path $MountedDiskImageRoot\* -Destination $TemporaryWorkingDirectory\tools\SetupFiles -Recurse 
#    Dismount-DiskImage -InputObject $MountedDiskImage
#    $ExesToIgnore = Get-ChildItem -Path $TemporaryWorkingDirectory\tools\SetupFiles -Recurse -Filter *.exe
#    foreach ($File in $EXEsToIgnore) {
#        New-Item -Path "$($File.FullName).ignore" -ItemType File | Out-Null
#    }
#
#    choco pack $TemporaryWorkingDirectory\SQLServer2016SP2VL.nuspec --outputdirectory $Destination --force
#
#    Remove-Item -Path $TemporaryWorkingDirectory -Recurse -Force    
#}

function Get-DriveLetterPathFromDiskImage {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$DiskImage
    )
    process {
        "$(($DiskImage | get-volume).DriveLetter):\"
    }
}

function Get-PathToWindows10USBInstallationSource {
    "\\tervis.prv\applications\Installers\Microsoft\Windows 10 Enterprise USB Install"
}

function Refresh-Windows10USBInstallationSource {    
    $LatestWindows10ISO = Get-ChildItem -File -Path "\\tervis.prv\applications\Installers\Microsoft" -Filter "SW_DVD5_WIN_ENT_10*_64BIT_*" |
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1

    $MountedDiskImage = Mount-DiskImage -ImagePath $LatestWindows10ISO.FullName -PassThru
    $MountedDiskImageRoot = $MountedDiskImage | Get-DriveLetterPathFromDiskImage
    $PathToWindows10USBInstallationSource = Get-PathToWindows10USBInstallationSource

    Remove-Item -Force -Recurse -Path $PathToWindows10USBInstallationSource
    New-Item -ItemType Directory -Path $PathToWindows10USBInstallationSource

    Read-Host "The following doesn't work"
    #Get-ChildItem -Path $MountedDiskImageRoot -Recurse | Copy-Item -Destination $PathToWindows10USBInstallationSource
    #Copy-Item -Path $MountedDiskImageRoot -Destination  $PathToWindows10USBInstallationSource
}

function Install-DotNet35OnWindows10 {
    $PathToWindows10USBInstallationSource = Get-PathToWindows10USBInstallationSource
    .\Dism.exe /online /enable-feature /featurename:NetFX3 /All /Source:"$PathToWindows10USBInstallationSource\sources\sxs" /LimitAccess
}