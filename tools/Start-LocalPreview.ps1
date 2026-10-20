[CmdletBinding()]
param([string]$SqlInstance = '.\SQLSERVER2025', [int]$Port = 8787)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$local = Join-Path $root '.local'
$site = Join-Path $local 'site'
$executable = Join-Path $env:ProgramFiles 'IIS Express\iisexpress.exe'
if (-not (Test-Path $executable)) { throw 'IIS Express no está instalado. Usa el instalador de IIS con una consola administradora.' }
if (Test-Path (Join-Path $local 'iis-express.pid')) {
    $previousId = [int](Get-Content (Join-Path $local 'iis-express.pid'))
    $previous = Get-Process -Id $previousId -ErrorAction SilentlyContinue
    if ($previous -and $previous.ProcessName -eq 'iisexpress') { throw 'La vista anterior sigue abierta. Detén el PID guardado en .local/iis-express.pid antes de iniciarla de nuevo.' }
}
New-Item -ItemType Directory -Path $site -Force | Out-Null
$source = Join-Path $root 'webapppolimusicv1_asp'
Get-ChildItem $source -File | Where-Object { $_.Extension -eq '.asp' -or $_.Name -eq 'web.config' } | Copy-Item -Destination $site -Force
foreach ($folder in @('assets','includes','SongFilesAndImages_resources')) {
    Copy-Item -LiteralPath (Join-Path $source $folder) -Destination $site -Recurse -Force
}
$privateFile = Join-Path $local 'connection.txt'
$ole = New-Object System.Data.OleDb.OleDbConnectionStringBuilder
$ole.Provider = 'SQLOLEDB'
$ole['Data Source'] = $SqlInstance
$ole['Initial Catalog'] = 'BDD_PoliMusic'
$ole['Integrated Security'] = 'SSPI'
[IO.File]::WriteAllText($privateFile, $ole.ConnectionString, [Text.Encoding]::ASCII)
# Solo la copia desechable cambia la ubicación privada; el sitio de producción no cambia.
$commonPath = Join-Path $site 'includes\common.asp'
$common = [IO.File]::ReadAllText($commonPath)
$common = $common.Replace('C:\ProgramData\PoliMusic\connection.txt', $privateFile)
[IO.File]::WriteAllText($commonPath, $common, (New-Object Text.UTF8Encoding($false)))
$template = Join-Path $env:ProgramFiles 'IIS Express\config\templates\PersonalWebServer\applicationhost.config'
[xml]$config = Get-Content -LiteralPath $template -Raw
$iisSite = $config.configuration.'system.applicationHost'.sites.site
$iisSite.SetAttribute('name', 'PoliMusicPreview')
$emptyRoot = Join-Path $local 'empty'
New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null
$iisSite.application.virtualDirectory.SetAttribute('physicalPath', $emptyRoot)
$iisSite.bindings.binding.SetAttribute('bindingInformation', ":${Port}:localhost")
$application = $config.CreateElement('application')
$application.SetAttribute('path', '/PoliMusic')
$virtualDirectory = $config.CreateElement('virtualDirectory')
$virtualDirectory.SetAttribute('path', '/')
$virtualDirectory.SetAttribute('physicalPath', $site)
[void]$application.AppendChild($virtualDirectory)
[void]$iisSite.AppendChild($application)
$configPath = Join-Path $local 'applicationhost.config'
$config.Save($configPath)
$process = Start-Process -FilePath $executable -ArgumentList @("/config:`"$configPath`"", '/site:PoliMusicPreview', '/systray:false') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $local 'iis-express.log') -RedirectStandardError (Join-Path $local 'iis-express-error.log')
$process.Id | Set-Content (Join-Path $local 'iis-express.pid')
Write-Output "IIS Express PID $($process.Id): http://localhost:$Port/PoliMusic/"
Write-Output 'Vista local con la identidad Windows actual. No reemplaza la instalación final en IIS.'
