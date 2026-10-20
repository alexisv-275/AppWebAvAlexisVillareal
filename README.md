# PoliMusic

Aplicación musical en ASP clásico y VBScript para IIS y SQL Server. Interfaz marfil, azul profundo y coral, catálogo en tarjetas, reproductor HTML5 y CRUD de canciones para administradores.

## Ejecutar en IIS

El código está en `webapppolimusicv1_asp`. El modelo original se conserva en `BDD_PoliMusic.sql`. **No ejecutes ese script sobre una base existente: contiene `DROP DATABASE`.**

Requisitos: Windows con IIS, ASP clásico, Windows PowerShell 5.1, proveedor OLE DB `SQLOLEDB` y una instancia **local** de SQL Server que ya tenga `BDD_PoliMusic` con sus tablas y datos. El instalador no crea ni reinicia la base. La cuenta que ejecuta la instalación debe ser administradora de Windows y tener permisos para crear el login del pool y conceder permisos en SQL Server.

Desde PowerShell **como administrador**, en esta carpeta:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Deploy-PoliMusic.ps1 -SqlInstance '.\SQLSERVER2025' -EnableAsp
```

Se encontró la base en `'.\SQLSERVER2025'` durante la implementación; adapta la instancia si cambia el entorno. El script copia únicamente los archivos de ejecución a `C:\inetpub\wwwroot\PoliMusic`, crea la aplicación `/PoliMusic` en `Default Web Site` y un pool dedicado sin CLR, y habilita ASP si se indica `-EnableAsp`. Si Windows solicita reiniciar, reinicia y repite. No cambia los bindings del sitio. `-ExecutionPolicy Bypass` afecta únicamente a ese proceso, sin cambiar la política del equipo.

Abre **http://localhost/PoliMusic/**. Si el sitio usa otro puerto, adapta la URL. Usuarios de demostración del SQL original: `userNormal` y `userAdmin`, ambos con contraseña `12345678`, si esos registros siguen sin cambios. Las contraseñas se comparan exactamente, distinguiendo mayúsculas. Los valores hexadecimales largos se rechazan: no se adivina ni se implementa un algoritmo para la credencial codificada del script.

La conexión con autenticación integrada se guarda en `C:\ProgramData\PoliMusic\connection.txt`, fuera del sitio, con lectura para el pool y control total para administradores/SYSTEM. El pool obtiene SELECT sobre usuarios, CRUD sobre canciones y SELECT/DELETE sobre sus tres tablas de asociación. No se conceden permisos para cambiar el esquema ni `db_owner`. Esta configuración automática presupone SQL Server en el mismo equipo.

No copies toda la carpeta del repositorio a wwwroot: utiliza el instalador para excluir SQL y herramientas. Las rutas `includes` y `SongFiles`, así como archivos `.sql`, quedan bloqueadas por request filtering. El endpoint `audio.asp?id=...` lee el MP3 desde disco tras comprobar la sesión; admite GET, HEAD y un rango de bytes para búsqueda en el reproductor.

## Uso y decisiones

- Sesión: `ID_USER`, `USERNAME`, `USER_TYPE` y fotografía opcional. Caduca tras 20 minutos de inactividad. Tipo 0: usuario; tipo 1: administrador. Las páginas validan permisos en el servidor.
- Las altas y ediciones seleccionan MP3 existentes en `SongFilesAndImages_resources/SongFiles`. Se aceptan nombres ASCII con letras, números, espacios, guiones, puntos, paréntesis y guion bajo; se rechazan rutas y `..`. Para ampliar la biblioteca, copia archivos a esa carpeta y concede lectura al pool.
- Los registros `~/songFiles/...` se resuelven al directorio real sin migraciones. Actualmente solo Adventure tiene archivo. Las otras canciones se muestran sin botón habilitado.
- No se suben ni borran archivos. Eliminar una canción retira sus asociaciones con artistas, álbumes y playlists en una transacción, conservando esas entidades y el MP3.
- `PLAYS` se inicializa en cero al crear y se conserva al editar; escuchar no escribe en la base.
- No hay portadas de canciones en el modelo: las tarjetas usan discos gráficos CSS. Las fotos de usuario usan recursos existentes.
- Las mutaciones y la salida requieren POST con token de 256 bits generado por SQL Server y almacenado en sesión. SQL parametrizado y codificación HTML para datos variables.

## Verificación

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Test-AspSyntax.ps1
node --check .\webapppolimusicv1_asp\assets\app.js
```

El primer comando compila los bloques VBScript con Windows Script Host; no ejecuta la aplicación ni sustituye las pruebas sobre IIS.

Si no tienes permisos de administrador y ya está instalado IIS Express, puedes revisar una copia local con tu identidad Windows (que necesita acceso a SQL Server):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Start-LocalPreview.ps1 -SqlInstance '.\SQLSERVER2025'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Test-Integration.ps1 -BaseUrl 'http://localhost:8787/PoliMusic/'
```

La vista usa `.local/site`, una carpeta ignorada por Git, y una conexión privada fuera de esa raíz pública. La prueba HTTP crea, edita y elimina una canción temporal; comprueba roles, tokens, rutas, codificación HTML, audio completo y rangos, bloqueo de recursos y cierre de sesión. Requiere las cuentas de demostración y Adventure. No debe ejecutarse contra una biblioteca ajena a estas pruebas. Para detener la vista: `Stop-Process -Id (Get-Content .local\iis-express.pid)`.

Para comprobar además la conservación de `PLAYS`, la eliminación de asociaciones y su rollback, añade `-SqlInstance '.\SQLSERVER2025'` a `Test-Integration.ps1`. Esta variante necesita permisos SQL con la identidad Windows actual; crea asociaciones únicamente para su canción temporal y provoca un timeout controlado de unos 15 segundos al eliminarla. Después confirma que se restauraron las asociaciones y elimina normalmente el registro de prueba.

Pruebas de aceptación en IIS:

1. Iniciar sesión con ambos roles; comprobar nombre, rol y navegación. Un login incorrecto debe devolver un mensaje genérico.
2. Con usuario normal solicitar `admin.asp`, `song-edit.asp` y `song-delete.asp` directamente; deben responder 403, también mediante POST.
3. Crear una canción temporal como administrador, editarla y eliminarla. Confirmar que el MP3 sigue existiendo. Verificar eliminación de asociaciones en una base de pruebas, sin borrar canciones reales para probar.
4. Reproducir Adventure, pausar, reanudar y cambiar la posición. Las otras cuatro canciones indican archivo ausente.
5. Probar tokens ausentes/incorrectos, identificadores inválidos y rutas manipuladas; no deben cambiar datos.
6. Cerrar sesión y usar Atrás, recargar y solicitar el audio; no se debe recuperar contenido protegido. La URL directa del MP3 debe responder 404 incluso con sesión.
7. Revisar catálogo vacío y error de conexión en un entorno de pruebas. Comprobar móvil (390 px), tablet (768 px) y escritorio (1440 px), teclado y foco visible.

Si aparece 500.19, revisa la instalación de IIS y las secciones bloqueadas en su configuración. Si aparece 503 con el mensaje de PoliMusic, revisa la conexión privada y los permisos del pool. No habilites la publicación de errores internos ni coloques credenciales dentro del sitio para solucionarlo.

El instalador guarda la autenticación anónima en `applicationHost.config` mediante `MACHINE/WEBROOT/APPHOST` y una ubicación específica para `Default Web Site/PoliMusic` (o el sitio elegido). Esto permite configurar la sección bloqueada desde el nivel de servidor. Si una versión anterior se detuvo en `Set-WebConfigurationProperty`, vuelve a ejecutar el instalador actualizado como administrador; reutiliza la aplicación y el pool creados y continúa la configuración.
