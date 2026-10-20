[CmdletBinding()]
param([string]$BaseUrl = 'http://localhost:8787/PoliMusic/', [string]$DemoPassword = '12345678', [string]$SqlInstance = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$clients = New-Object Collections.Generic.List[System.Net.Http.HttpClient]
$script:checks = 0
function New-Client {
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $false
    $handler.CookieContainer = New-Object Net.CookieContainer
    $client = New-Object System.Net.Http.HttpClient $handler
    $client.BaseAddress = New-Object Uri $BaseUrl
    $clients.Add($client)
    return $client
}
function Send($client, $path, $expected, $form = $null, $method = 'GET', $range = '') {
    $request = New-Object System.Net.Http.HttpRequestMessage (New-Object System.Net.Http.HttpMethod $method), $path
    if ($null -ne $form) {
        $dictionary = New-Object 'Collections.Generic.Dictionary[string,string]'
        foreach ($key in $form.Keys) { $dictionary.Add($key, [string]$form[$key]) }
        $request.Content = New-Object System.Net.Http.FormUrlEncodedContent $dictionary
    }
    if ($range) { [void]$request.Headers.TryAddWithoutValidation('Range', $range) }
    $response = $client.SendAsync($request).GetAwaiter().GetResult()
    if ([int]$response.StatusCode -ne $expected) {
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        throw "$method $path esperaba $expected, recibió $([int]$response.StatusCode): $($body.Substring(0,[Math]::Min(600,$body.Length)))"
    }
    $script:checks++
    $request.Dispose()
    return $response
}
function Html($response) { return $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() }
function Csrf($content) {
    $match = [regex]::Match($content, 'name="csrf" value="([A-F0-9]{64})"')
    if (-not $match.Success) { throw 'No se encontró un token válido.' }
    return $match.Groups[1].Value
}
function Assert($condition, $message) {
    if (-not $condition) { throw $message }
    $script:checks++
}
function Login($client, $name) {
    $page = Html (Send $client 'login.asp' 200)
    $response = Send $client 'login.asp' 302 @{csrf=(Csrf $page); username=$name; password=$DemoPassword} 'POST'
    Assert ($response.Headers.Location.ToString().EndsWith('default.asp')) 'El login no redirige al catálogo.'
    return Html (Send $client 'default.asp' 200)
}
$testId = 0
$admin = $null
$database = $null
try {
    $anonymous = New-Client
    $normal = New-Client
    $admin = New-Client
    [void](Send $anonymous 'default.asp' 302)
    [void](Send $anonymous 'audio.asp?id=1' 302)
    [void](Send $anonymous 'includes/common.asp' 404)
    [void](Send $anonymous 'BDD_PoliMusic.sql' 404)
    [void](Send $anonymous 'SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3' 404)
    $login = Html (Send $anonymous 'login.asp' 200)
    [void](Send $anonymous 'login.asp' 403 @{username='userAdmin';password=$DemoPassword} 'POST')
    $wrong = Html (Send $anonymous 'login.asp' 200 @{csrf=(Csrf $login);username='userAdmin';password='INCORRECTA'} 'POST')
    Assert ($wrong -match 'incorrectos') 'Falta mensaje genérico de error de login.'
    $catalog = Login $normal 'userNormal'
    Assert ($catalog -match 'userNormal') 'La bienvenida no incluye el nombre de sesión.'
    Assert ($catalog -notmatch 'Administrar canciones') 'El usuario normal ve navegación administrativa.'
    foreach ($page in @('admin.asp','song-edit.asp','song-delete.asp?id=1')) {
        [void](Send $normal $page 403)
        [void](Send $normal $page 403 @{csrf=(Csrf $catalog);id='1';song_name='NO GUARDAR';song_path='~/songFiles/bensound-adventure.mp3'} 'POST')
    }
    $adventure = [regex]::Match($catalog, 'data-song-id="([0-9]+)" data-song-name="Adventure"')
    Assert $adventure.Success 'No se encontró Adventure en la base de demostración.'
    $id = $adventure.Groups[1].Value
    $response = Send $normal "audio.asp?id=$id" 206 $null 'GET' 'bytes=0-99'
    $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    Assert ($bytes.Length -eq 100) 'El rango no devolvió 100 bytes.'
    Assert ($response.Content.Headers.ContentType.MediaType -eq 'audio/mpeg') 'Tipo MIME incorrecto.'
    $response = Send $normal "audio.asp?id=$id" 200
    $fullAudio = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    Assert ($fullAudio.Length -gt 100 -and $fullAudio.Length -eq $response.Content.Headers.ContentLength) 'El MP3 completo no se transmite correctamente.'
    [void](Send $normal "audio.asp?id=$id" 206 $null 'GET' 'bytes=-100')
    [void](Send $normal "audio.asp?id=$id" 200 $null 'HEAD')
    [void](Send $normal "audio.asp?id=$id" 416 $null 'GET' 'bytes=999999999999-')
    [void](Send $normal 'audio.asp?id=abc' 400)
    [void](Send $normal 'audio.asp?id=2147483647' 404)
    Assert ($catalog -match 'Audio no disponible') 'No se indican audios ausentes.'
    Write-Output 'OK: login, sesión, roles, archivos privados, audio y rangos.'

    $adminCatalog = Login $admin 'userAdmin'
    Assert ($adminCatalog -match 'Administrar canciones') 'Falta acceso administrativo.'
    $edit = Html (Send $admin 'song-edit.asp' 200)
    $name = 'PoliMusic-Test-' + [guid]::NewGuid().ToString('N').Substring(0,10)
    $form = @{csrf=(Csrf $edit);id='';song_name=$name;song_path='~/songFiles/bensound-adventure.mp3'}
    $invalid = $form.Clone(); $invalid.song_path = '~/songFiles/../../BDD_PoliMusic.sql'
    $invalidPage = Html (Send $admin 'song-edit.asp' 200 $invalid 'POST')
    Assert ($invalidPage -match 'Selecciona un archivo MP3 disponible') 'No se rechazó la ruta manipulada.'
    [void](Send $admin 'song-edit.asp' 403 @{id='';song_name=$name;song_path=$form.song_path} 'POST')
    [void](Send $admin 'song-edit.asp' 302 $form 'POST')
    $listing = Html (Send $admin 'admin.asp' 200)
    $row = [regex]::Match($listing, '<tr><td[^>]+><strong>' + [regex]::Escape($name) + '</strong>.*?song-edit.asp\?id=([0-9]+)', 'Singleline')
    Assert $row.Success 'La canción creada no aparece en administración.'
    $testId = [int]$row.Groups[1].Value
    $edit = Html (Send $admin "song-edit.asp?id=$testId" 200)
    $form = @{csrf=(Csrf $edit);id=$testId;song_name=($name + '<&');song_path='~/songFiles/bensound-adventure.mp3'}
    [void](Send $admin 'song-edit.asp' 302 $form 'POST')
    $listing = Html (Send $admin 'admin.asp' 200)
    Assert ($listing.Contains($name + '&lt;&amp;')) 'El nombre no se editó o no se codifica HTML.'
    if ($SqlInstance) {
        $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
        $builder['Data Source'] = $SqlInstance
        $builder['Initial Catalog'] = 'BDD_PoliMusic'
        $builder['Integrated Security'] = $true
        $builder['TrustServerCertificate'] = $true
        $database = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
        $database.Open()
        $command = $database.CreateCommand()
        $command.Parameters.Add('@id', [System.Data.SqlDbType]::Int).Value = $testId
        $command.CommandText = 'SELECT PLAYS FROM TBL_SONG WHERE ID_SONG = @id'
        Assert ($command.ExecuteScalar() -eq 0) 'Editar la canción cambió PLAYS.'
        # Solo se asocia la canción temporal con entidades ya existentes.
        $command.CommandText = @'
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) SELECT MIN(ID_ALBUM), @id FROM TBL_ALBUM HAVING COUNT(*) > 0;
INSERT INTO TBL_PLAYER (ID_ARTIST, ID_SONG) SELECT MIN(ID_ARTIST), @id FROM TBL_ARTIST HAVING COUNT(*) > 0;
INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) SELECT MIN(ID_PLAYLIST), @id FROM TBL_PLAYLIST HAVING COUNT(*) > 0;
COMMIT;
'@
        [void]$command.ExecuteNonQuery()
        $command.CommandText = 'SELECT (SELECT COUNT(*) FROM TBL_TRACKLIST WHERE ID_SONG=@id) + (SELECT COUNT(*) FROM TBL_PLAYER WHERE ID_SONG=@id) + (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_SONG=@id)'
        Assert ($command.ExecuteScalar() -eq 3) 'Se requieren un álbum, un artista y una playlist para probar las asociaciones.'
        $confirmation = Html (Send $admin "song-delete.asp?id=$testId" 200)
        $lock = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
        $lock.Open()
        $transaction = $lock.BeginTransaction()
        try {
            # Un bloqueo compartido deja leer la confirmación, pero fuerza timeout
            # al borrar el padre, después de haber borrado sus asociaciones.
            $hold = $lock.CreateCommand()
            $hold.Transaction = $transaction
            $hold.CommandText = 'SELECT ID_SONG FROM TBL_SONG WITH (HOLDLOCK, ROWLOCK) WHERE ID_SONG=@id'
            $hold.Parameters.Add('@id', [System.Data.SqlDbType]::Int).Value = $testId
            [void]$hold.ExecuteScalar()
            $failedDelete = Html (Send $admin 'song-delete.asp' 200 @{id=$testId;csrf=(Csrf $confirmation)} 'POST')
            Assert ($failedDelete -match 'No se pudo eliminar') 'El fallo de eliminación no muestra el mensaje esperado.'
            Assert ($command.ExecuteScalar() -eq 3) 'La transacción no restauró todas las asociaciones.'
        } finally {
            $transaction.Rollback()
            $lock.Dispose()
        }
        Write-Output 'OK: PLAYS conservado y rollback de tres asociaciones ante fallo de eliminación.'
    }
    [void](Send $admin 'song-delete.asp' 403 @{id=$testId;csrf='incorrecto'} 'POST')
    $confirmation = Html (Send $admin "song-delete.asp?id=$testId" 200)
    [void](Send $admin 'song-delete.asp' 302 @{id=$testId;csrf=(Csrf $confirmation)} 'POST')
    [void](Send $admin "song-edit.asp?id=$testId" 404)
    if ($database) {
        $command.CommandText = 'SELECT (SELECT COUNT(*) FROM TBL_SONG WHERE ID_SONG=@id) + (SELECT COUNT(*) FROM TBL_TRACKLIST WHERE ID_SONG=@id) + (SELECT COUNT(*) FROM TBL_PLAYER WHERE ID_SONG=@id) + (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_SONG=@id)'
        Assert ($command.ExecuteScalar() -eq 0) 'La eliminación dejó un registro o asociaciones pendientes.'
    }
    $testId = 0
    $response = Send $normal "audio.asp?id=$id" 206 $null 'GET' 'bytes=0-9'
    Assert ($response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult().Length -eq 10) 'Se eliminó el MP3 al eliminar el registro.'
    Write-Output 'OK: alta, edición, codificación HTML, validación de rutas y eliminación de canción temporal.'

    [void](Send $normal 'logout.asp' 405)
    [void](Send $normal 'logout.asp' 403 @{csrf='incorrecto'} 'POST')
    $response = Send $normal 'default.asp' 200
    Assert ($response.Headers.CacheControl.NoStore) 'Falta no-store en el catálogo.'
    $token = Csrf (Html $response)
    [void](Send $normal 'logout.asp' 302 @{csrf=$token} 'POST')
    [void](Send $normal 'default.asp' 302)
    [void](Send $normal "audio.asp?id=$id" 302)
    [void](Send $normal 'admin.asp' 302)
    $adminPage = Html (Send $admin 'admin.asp' 200)
    [void](Send $admin 'logout.asp' 302 @{csrf=(Csrf $adminPage)} 'POST')
    Write-Output "OK: cierre de sesión, caché y revocación de acceso. $script:checks comprobaciones superadas."
} finally {
    if ($testId -gt 0 -and $admin) {
        $page = Html (Send $admin "song-delete.asp?id=$testId" 200)
        [void](Send $admin 'song-delete.asp' 302 @{id=$testId;csrf=(Csrf $page)} 'POST')
        Write-Output 'Se retiró el registro temporal después de la prueba.'
    }
    foreach ($client in $clients) { $client.Dispose() }
    if ($database) { $database.Dispose() }
}
