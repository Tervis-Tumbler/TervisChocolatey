$ChocolateyPackageGroups = [PSCustomObject][Ordered] @{
    Name = "StandardOfficeEndpoint"
    ChocolateyPackageConfigPackages = @(
        (
@"
CiscoAnyConnect
camunda-modeler
googlechrome
firefox
autohotkey
greenshot
office365-deployment-tool
adobereader
microsoft-teams
TervisTeamViewerHost
sql2012.nativeclient
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) +
        @(New-TervisChocolateyPackageConfigPackage -id jre8 -version 8.0.191.20181114 -packageParameters "/exclude:64")
    )
},
[PSCustomObject][Ordered] @{
    Name = "ContactCenter"
    ChocolateyPackageConfigPackages =  @(
@"
paint.net
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
rufus
speedcrunch
sql-server-management-studio
sumatrapdf
sysinternals
todoist
vlc
visualstudiocode
windirstat
winmerge
wireshark
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
                (Get-PasswordstatePassword -ID 4096).Password
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
                (Get-PasswordstatePassword -ID 4096).Password
            )"
        ))
    )
},
[PSCustomObject][Ordered] @{
    Name = "BartenderLicenseServer"
    ChocolateyPackageConfigPackages =  @(        
        (New-TervisChocolateyPackageConfigPackage -id bartender -version 11.0.4.3127 -packageParameters $(
            "Edition=EA ADDLOCAL=LicenseServer,Bartender REMOVE=AdministrationConsole,Librarian,HistoryExplorer,BatchMaker,PrintStation,PrinterMaestro,ReprintConsole PKC=$(
                (Get-PasswordstatePassword -ID 4096).Password
            )"
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
        (New-TervisChocolateyPackageConfigPackage -id jre8 -version 8.0.191.20181114 -packageParameters "/exclude:64" )
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
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) + @(
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
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
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    ) + @(
        (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
    )
},
[PSCustomObject][Ordered] @{
    Name = "WCSRemoteApp"
    ChocolateyPackageConfigPackages =  @(
@"
FoxitReader
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    ) + (
        @(
            (New-TervisChocolateyPackageConfigPackage -id javaruntime -version 7.0.60)
        )
#        @(New-TervisChocolateyPackageConfigPackage -id jre8 -packageParameters "/exclude:64")
    )
},
[PSCustomObject][Ordered] @{
    Name = "DataLoadClassic"
    ChocolateyPackageConfigPackages =  @(
        @(New-TervisChocolateyPackageConfigPackage -id jre8 -version 8.0.191.20181114)
    )
},
[PSCustomObject][Ordered] @{
    Name = "WindowsApps"
    ChocolateyPackageConfigPackages =  @(
@"
googlechrome
firefox
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    ) + @(
        (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
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
            (New-TervisChocolateyPackageConfigPackage -id jre8 -version 8.0.191.20181114),
            (New-TervisChocolateyPackageConfigPackage -id firefox -version 24.0),
            (New-TervisChocolateyPackageConfigPackage -id ghostscript.app -version 9.20),
            (New-TervisChocolateyPackageConfigPackage -id gimp -version 2.8.20)
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "EBSBusinessIntelligenceRemoteApp"
    ChocolateyPackageConfigPackages =  @(
@"
flashplayerplugin
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
    ) + (
        @(
            (New-TervisChocolateyPackageConfigPackage -id javaruntime -version 7.0.60),
            (New-TervisChocolateyPackageConfigPackage -id firefox -version 24.0),
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "EBSDiscovererRemoteApp"
    ChocolateyPackageConfigPackages = @(
            (New-TervisChocolateyPackageConfigPackage -id javaruntime -version 7.0.60),
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
        )
},
[PSCustomObject][Ordered] @{
    Name = "FillRoomSurface"
    ChocolateyPackageConfigPackages = @(
        (
@"
autohotkey
TervisTeamViewerHost
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "SurfaceMES"
    ChocolateyPackageConfigPackages = @(
        (
@"
autohotkey
TervisTeamViewerHost
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "SilverlightIE"
    ChocolateyPackageConfigPackages = @(
        (
@"
silverlight
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "MESStation"
    ChocolateyPackageConfigPackages = @(
        (
@"
adobereader
TervisTeamViewerHost
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "SCCM2016"
    ChocolateyPackageConfigPackages = @(
        (
@"
sql-server-management-studio
windows-adk-all
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "UnifiController"
    ChocolateyPackageConfigPackages = @(
        (
@"
ubiquiti-unifi-controller
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "PrintServer"
    ChocolateyPackageConfigPackages = @(
        (
@"
google-cloud-print-connector
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "ShipStation"
    ChocolateyPackageConfigPackages = @(
        (
@"
googlechrome
firefox
greenshot
adobereader
TervisTeamViewerHost
sql2012.nativeclient
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) +
        @(
            (New-TervisChocolateyPackageConfigPackage -id jre8 -version 8.0.191.20181114 -packageParameters "/exclude:64"),
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense")
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "StoresBackOffice"
    ChocolateyPackageConfigPackages = @(
        (
@"
googlechrome
firefox
greenshot
javaruntime
TervisTeamViewerHost
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) + @(
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense")
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "SharedOfficeEndpoint"
    ChocolateyPackageConfigPackages = @(
        (
@"
CiscoAnyConnect
camunda-modeler
googlechrome
firefox
autohotkey
greenshot
adobereader
microsoft-teams
TervisTeamViewerHost
sql2012.nativeclient
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) +
        @(
            (New-TervisChocolateyPackageConfigPackage -id jre8 -version 8.0.191.20181114 -packageParameters "/exclude:64"),
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense")
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "ITToolbox"
    ChocolateyPackageConfigPackages = @(
        (
@"
googlechrome
firefox
javaruntime
visualstudiocode
angryip
sql-server-management-studio
putty
rdm
sqlanywhereclient
git
github-desktop
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        ) + @(
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "IQ2Welder"
    ChocolateyPackageConfigPackages = @(
        (
@"
TervisTeamViewerHostEngineering
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "Exchange"
    ChocolateyPackageConfigPackages = @(
        (
@"
vcredist2013
"@ -split "`r`n" | New-TervisChocolateyPackageConfigPackage
        )
    )
},
[PSCustomObject][Ordered] @{
    Name = "ExcelTask"
    ChocolateyPackageConfigPackages = @(
            (New-TervisChocolateyPackageConfigPackage -id office365-deployment-tool -packageParameters "/VolumeLicense /Shared")
        )
}