[CmdletBinding()]
param(
    [string]$SqlInstance = '.\SQLEXPRESS2017',
    [string]$SiteName = 'Default Web Site',
    [switch]$EnableAsp
)
$ErrorActionPreference = 'Stop'
$destination = 'C:\inetpub\wwwroot\PoliMusic'
$secretDirectory = 'C:\ProgramData\PoliMusic'
$poolName = 'PoliMusic'
$source = Join-Path $PSScriptRoot '..\webapppolimusicv1_asp'
$admin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Ejecuta este script desde PowerShell como administrador.'
}
Import-Module WebAdministration
if (-not (Test-Path "IIS:\Sites\$SiteName")) { throw "No existe el sitio IIS: $SiteName" }
$feature = Get-WindowsOptionalFeature -Online -FeatureName IIS-ASP
if ($feature.State -ne 'Enabled') {
    if (-not $EnableAsp) { throw 'ASP clásico no está habilitado. Repite con -EnableAsp.' }
    $result = Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -All -NoRestart
    if ($result.RestartNeeded) { throw 'Windows requiere reiniciar. Reinicia y vuelve a ejecutar el despliegue.' }
}

# Solo comprobar: nunca ejecutar el script BDD_PoliMusic.sql.
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $SqlInstance
$builder['Initial Catalog'] = 'BDD_PoliMusic'
$builder['Integrated Security'] = $true
$builder['Connect Timeout'] = 5
$builder['TrustServerCertificate'] = $true
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$connection.Open()
try {
    $check = $connection.CreateCommand()
    $check.CommandText = "SELECT COUNT(*) FROM sys.tables WHERE name IN ('TBL_USER','TBL_SONG','TBL_TRACKLIST','TBL_PLAYER','TBL_PLAYLIST_SONG')"
    if ($check.ExecuteScalar() -ne 5) { throw 'La base existente no contiene las tablas requeridas.' }

    if (-not (Test-Path "IIS:\AppPools\$poolName")) { New-WebAppPool -Name $poolName | Out-Null }
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name managedRuntimeVersion -Value ''
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name processModel.identityType -Value 4
    if (-not (Test-Path $destination)) { New-Item -ItemType Directory -Path $destination | Out-Null }
    $existing = Get-WebApplication -Site $SiteName -Name 'PoliMusic'
    if ($existing -and [IO.Path]::GetFullPath($existing.PhysicalPath) -ne $destination) { throw 'Ya existe /PoliMusic con otra ruta física. No se reemplazará.' }

    # Lista explícita: excluye SQL, herramientas y documentación del sitio público.
    Get-ChildItem -LiteralPath $source -File | Where-Object { $_.Extension -eq '.asp' -or $_.Name -eq 'web.config' } | Copy-Item -Destination $destination -Force
    foreach ($folder in @('assets','includes','SongFilesAndImages_resources')) {
        Copy-Item -LiteralPath (Join-Path $source $folder) -Destination $destination -Recurse -Force
    }
    if (-not $existing) {
        New-WebApplication -Site $SiteName -Name 'PoliMusic' -PhysicalPath $destination -ApplicationPool $poolName | Out-Null
    } else {
        Set-ItemProperty "IIS:\Sites\$SiteName\PoliMusic" -Name applicationPool -Value $poolName
    }
    # Esta sección está bloqueada para web.config por defecto. Guardar en
    # applicationHost.config, con ubicación limitada a esta aplicación.
    $applicationLocation = "$SiteName/PoliMusic"
    Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $applicationLocation -Filter system.webServer/security/authentication/anonymousAuthentication -Name enabled -Value $true
    Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Location $applicationLocation -Filter system.webServer/security/authentication/anonymousAuthentication -Name userName -Value ''

    # El archivo privado solo puede ser leído por el pool y los administradores.
    if (-not (Test-Path $secretDirectory)) { New-Item -ItemType Directory -Path $secretDirectory | Out-Null }
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @('S-1-5-18','S-1-5-32-544')) {
        $identity = New-Object Security.Principal.SecurityIdentifier $sid
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
    }
    $rule = New-Object Security.AccessControl.FileSystemAccessRule('IIS AppPool\PoliMusic', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $secretDirectory -AclObject $acl
    $ole = New-Object System.Data.OleDb.OleDbConnectionStringBuilder
    $ole.Provider = 'SQLOLEDB'
    $ole['Data Source'] = $SqlInstance
    $ole['Initial Catalog'] = 'BDD_PoliMusic'
    $ole['Integrated Security'] = 'SSPI'
    [IO.File]::WriteAllText((Join-Path $secretDirectory 'connection.txt'), $ole.ConnectionString, [Text.Encoding]::ASCII)
    $publicAcl = Get-Acl -LiteralPath $destination
    $rule = New-Object Security.AccessControl.FileSystemAccessRule('IIS AppPool\PoliMusic', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    $publicAcl.AddAccessRule($rule)
    Set-Acl -LiteralPath $destination -AclObject $publicAcl

    # Identidad local del pool: permisos mínimos, sin db_owner ni cambios de esquema.
    $grant = $connection.CreateCommand()
    $grant.CommandText = @'
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'IIS APPPOOL\PoliMusic')
    CREATE LOGIN [IIS APPPOOL\PoliMusic] FROM WINDOWS;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'IIS APPPOOL\PoliMusic')
    CREATE USER [IIS APPPOOL\PoliMusic] FOR LOGIN [IIS APPPOOL\PoliMusic];
GRANT SELECT ON dbo.TBL_USER TO [IIS APPPOOL\PoliMusic];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.TBL_SONG TO [IIS APPPOOL\PoliMusic];
GRANT SELECT, DELETE ON dbo.TBL_TRACKLIST TO [IIS APPPOOL\PoliMusic];
GRANT SELECT, DELETE ON dbo.TBL_PLAYER TO [IIS APPPOOL\PoliMusic];
GRANT SELECT, DELETE ON dbo.TBL_PLAYLIST_SONG TO [IIS APPPOOL\PoliMusic];
'@
    $grant.ExecuteNonQuery() | Out-Null
} finally { $connection.Dispose() }
Write-Output 'Instalación terminada: http://localhost/PoliMusic/'
Write-Output 'El modelo y los datos existentes no se han modificado.'
