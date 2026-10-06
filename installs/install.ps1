# Windows PowerShell 5.1. Mirrors LB Setup Python / LB Installer from installer.gh.
[CmdletBinding()]
param([switch]$CheckOnly, [switch]$SkipRadiance)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Download-File($Url, $Destination) {
    Write-Host "Descarcare: $Url"
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile "$Destination.partial"
    Move-Item -LiteralPath "$Destination.partial" -Destination $Destination -Force
}
function Run-Python([string[]]$Arguments) {
    & $script:python @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Python a esuat ($LASTEXITCODE): $Arguments" }
}
function Copy-Tree($Source, $Destination) {
    if (!(Test-Path -LiteralPath $Source -PathType Container)) { throw "Folder lipsa: $Source" }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | Copy-Item -Destination $Destination -Recurse -Force
}
function Install-Repo($Repo, $Version, $Subfolder, $Destination) {
    $zip = Join-Path $script:work "$Repo.zip"
    Download-File "https://github.com/ladybug-tools/$Repo/archive/refs/tags/v$Version.zip" $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $script:work -Force
    Copy-Tree (Join-Path $script:work "$Repo-$Version/$Subfolder") $Destination
}
function Add-SearchPath($File, $Path) {
    New-Item -ItemType Directory -Path (Split-Path $File) -Force | Out-Null
    $lines = @()
    if (Test-Path -LiteralPath $File) { $lines = @(Get-Content -LiteralPath $File) }
    if ($Path -notin $lines) { [IO.File]::WriteAllLines($File, [string[]](@($lines) + $Path), (New-Object Text.UTF8Encoding($false))) }
}
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $rhino = Join-Path $env:ProgramFiles 'Rhino 8/System/Rhino.exe'
    if (!(Test-Path -LiteralPath $rhino)) { throw 'Rhino 8 nu este instalat in Program Files.' }
    if (Get-Process Rhino -ErrorAction SilentlyContinue) { throw 'Inchideti toate instantele Rhino inainte de instalare.' }
    foreach ($folder in @('ladybug-tools-1-10-0', 'DecodingSpaces 2021.10.11', 'EleFront')) {
        if (!(Test-Path -LiteralPath (Join-Path $PSScriptRoot $folder))) { throw "Folder lipsa: $folder" }
    }
    $lbHome = $env:USERPROFILE
    if ($env:HOME) { $lbHome = $env:HOME }
    $lb = Join-Path $lbHome 'ladybug_tools'
    $script:python = Join-Path $lb 'python/python.exe'
    $sitePackages = Join-Path $lb 'python/Lib/site-packages'
    $uo = Join-Path $env:APPDATA 'Grasshopper/UserObjects'
    $libraries = Join-Path $env:APPDATA 'Grasshopper/Libraries'
    Write-Host "Ladybug Tools: $lb"
    Write-Host "Grasshopper: $uo ; $libraries"
    if ($CheckOnly) { Write-Host 'Verificarile preliminare au trecut. Nu s-a instalat nimic.'; exit 0 }
    $script:work = Join-Path $env:TEMP ('scholarh-install-' + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $script:work -Force | Out-Null
    New-Item -ItemType Directory -Path $lb -Force | Out-Null
    if (!(Test-Path -LiteralPath $script:python)) {
        $zip = Join-Path $script:work 'python.zip'
        Download-File 'https://storage.googleapis.com/pollination-public/plugins/installerAssets/python3.10.10.zip' $zip
        Expand-Archive -LiteralPath $zip -DestinationPath $lb -Force
    }
    $env:PYTHONHOME = ''
    $env:PYTHONPATH = ''
    Run-Python @('-c', 'import sys; assert sys.version_info[:3] == (3,10,10), sys.version')
    foreach ($package in @('lbt-dragonfly==0.12.360', 'fairyfly-therm==0.10.0', 'lbt-recipes==0.27.1', 'ladybug-rhino==1.44.9')) {
        Run-Python @('-m', 'pip', 'install', '--disable-pip-version-check', $package)
    }
    New-Item -ItemType Directory -Path $uo, $libraries -Force | Out-Null
    Run-Python @('-m', 'pip', 'install', 'lbt-grasshopper==1.10.6', '--target', $uo, '--upgrade')
    Run-Python @('-m', 'pip', 'install', 'ladybug-grasshopper-dotnet==1.3.7', '--target', $libraries, '--upgrade')
    $requirements = Join-Path $uo 'requirements.txt'
    $rows = @()
    if (Test-Path -LiteralPath $requirements) { $rows = @(Get-Content -LiteralPath $requirements | Where-Object { $_ -notmatch '^lbt-grasshopper==' }) }
    @($rows) + 'lbt-grasshopper==1.10.6' | Set-Content -LiteralPath $requirements -Encoding ASCII
    $resources = Join-Path $lb 'resources'
    Install-Repo 'lbt-grasshopper-samples' '1.10.0' 'samples' (Join-Path $resources 'samples')
    Install-Repo 'honeybee-openstudio-gem' '2.38.23' 'lib' (Join-Path $resources 'measures/honeybee_openstudio_gem/lib')
    Install-Repo 'lbt-measures' '0.3.2' 'lib' (Join-Path $resources 'measures')
    Run-Python @('-m', 'pip', 'install', 'honeybee-energy-standards==2.3.0', '--target', (Join-Path $resources 'standards'), '--upgrade')
    foreach ($sub in @('standards/constructions', 'standards/constructionsets', 'standards/schedules', 'standards/programtypes', 'standards/modifiers', 'standards/modifiersets', 'weather', 'measures')) {
        New-Item -ItemType Directory -Path (Join-Path $env:APPDATA "ladybug_tools/$sub") -Force | Out-Null
    }
    # Rhino must be closed. Preserve other search paths and back up its settings.
    $settingsDir = Join-Path $env:APPDATA 'McNeel/Rhinoceros/8.0/Plug-ins/IronPython (814d908a-e25c-493d-97e9-ee3861957f49)/settings'
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    $defaultSettings = Join-Path $settingsDir 'settings-Scheme__Default.xml'
    if (!(Test-Path -LiteralPath $defaultSettings)) { '<settings id="2.0"><settings /></settings>' | Set-Content -LiteralPath $defaultSettings -Encoding UTF8 }
    foreach ($file in Get-ChildItem -LiteralPath $settingsDir -Filter 'settings-Scheme*.xml') {
        Copy-Item -LiteralPath $file.FullName -Destination "$($file.FullName).scholarh.bak" -Force
        [xml]$doc = Get-Content -LiteralPath $file.FullName -Raw
        $settings = $doc.DocumentElement.SelectSingleNode('settings')
        if ($null -eq $settings) { $settings = $doc.CreateElement('settings'); $doc.DocumentElement.AppendChild($settings) | Out-Null }
        $entry = $settings.SelectSingleNode('entry[@key="SearchPaths"]')
        if ($null -eq $entry) { $entry = $doc.CreateElement('entry'); $entry.SetAttribute('key', 'SearchPaths'); $settings.AppendChild($entry) | Out-Null }
        $paths = @($entry.InnerText -split ';' | Where-Object { $_ })
        if ($sitePackages -notin $paths) { $entry.InnerText = (@($paths) + $sitePackages) -join ';' }
        $doc.Save($file.FullName)
    }
    foreach ($name in @('python-2.pth', 'python-3.pth')) { Add-SearchPath (Join-Path $env:USERPROFILE ".rhinocode/$name") $sitePackages }
    Copy-Tree (Join-Path $PSScriptRoot 'DecodingSpaces 2021.10.11') (Join-Path $libraries 'DecodingSpaces 2021.10.11')
    Copy-Tree (Join-Path $PSScriptRoot 'DecodingSpaces 2021.10.11/UserObjects') (Join-Path $uo 'DecodingSpaces')
    Copy-Tree (Join-Path $PSScriptRoot 'EleFront') (Join-Path $libraries 'EleFront')
    foreach ($folder in @((Join-Path $libraries 'DecodingSpaces 2021.10.11'), (Join-Path $libraries 'EleFront'), (Join-Path $libraries 'ladybug_grasshopper_dotnet'))) {
        Get-ChildItem -LiteralPath $folder -Recurse -File | Unblock-File
    }
    if (!$SkipRadiance) {
        $exe = Join-Path $PSScriptRoot 'Radiance_4ee32974_Windows.exe'
        if (!(Test-Path -LiteralPath $exe)) { Download-File 'https://github.com/LBNL-ETA/Radiance/releases/download/rad5R4/Radiance_4ee32974_Windows.exe' $exe }
        # NSIS: /D must be the final argument, without quotes.
        Write-Host 'Instalare Radiance 5.4 (2023-11-05) in C:\Radiance (poate cere drepturi de administrator)...'
        $process = Start-Process -FilePath $exe -ArgumentList '/S /D=C:\Radiance' -WindowStyle Hidden -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Radiance a esuat: $($process.ExitCode)" }
        if (!(Test-Path -LiteralPath 'C:\Radiance\bin\rtrace.exe')) { throw 'Radiance nu a creat C:\Radiance\bin\rtrace.exe.' }
        $userPath = [string][Environment]::GetEnvironmentVariable('Path', 'User')
        if ('C:\Radiance\bin' -notin @($userPath -split ';')) { [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';C:\Radiance\bin').TrimStart(';'), 'User') }
    }
    Run-Python @('-m', 'pip', 'check')
    Run-Python @('-c', 'import ladybug, ladybug_rhino, honeybee, honeybee_energy, honeybee_radiance, dragonfly, lbt_recipes')
    Write-Host 'Instalarea s-a terminat. Porniti Rhino 8 si verificati componentele in Grasshopper.'
    Write-Host 'EleFront 5.4.1 a fost copiat in folderul Grasshopper Libraries.'
    Write-Host 'OpenStudio este necesar separat pentru simularile energetice.'
    Write-Host "Arhivele descarcate pentru diagnostic se afla in: $script:work"
} catch {
    Write-Error -Message $_ -ErrorAction Continue
    exit 1
}
