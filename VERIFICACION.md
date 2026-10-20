# Verificación de PoliMusic

Fecha: 20 de octubre de 2026.

## Comprobado

- Siete páginas ASP compilan como VBScript con Windows Script Host.
- JavaScript válido con `node --check`; scripts PowerShell y XML de configuración válidos.
- Aplicación ejecutada con ASP real en IIS Express, bajo `/PoliMusic/`, conectada a la base existente de `.\SQLSERVER2025` mediante autenticación Windows.
- **72 comprobaciones de integración superadas**: login, roles, solicitudes administrativas directas, tokens, rutas manipuladas, codificación HTML, CRUD temporal, conservación de `PLAYS`, MP3 completo y rangos, archivos privados, caché y cierre de sesión.
- Eliminación con tres asociaciones comprobada. Un bloqueo compartido sobre la canción temporal provocó el timeout de 15 segundos; se verificó que las tres asociaciones se restauraron. Después se eliminó la canción temporal normalmente.
- Estado vacío comprobado filtrando únicamente la consulta en una copia desechable del sitio, sin vaciar la base.
- Error de conexión comprobado en esa copia: HTTP 503 con mensaje genérico, sin publicar detalles internos. Se restauró la conexión al terminar.
- El script SQL original permanece intacto. SHA256: `9E78D8675DE48532347DA2C1B402D13468DD1172FAFF4F0B4B9E41BBF4764779`.

Las pruebas crean y eliminan registros temporales; no reinician la secuencia IDENTITY. Se conservaron las canciones y entidades originales.

## Pendiente por el entorno

- El instalador para `C:\inetpub\wwwroot\PoliMusic` se detuvo en su comprobación inicial: la cuenta de ejecución no tiene privilegios de administrador de Windows. No se configuró el IIS principal ni el pool de producción. IIS Express se utilizó para validar la aplicación.
- Sin navegador conectado, no se realizó inspección visual de escritorio/móvil ni interacción manual por teclado. Los estilos incluyen las distribuciones y estados accesibles previstos, pendientes de revisión visual.

Para completar la instalación, abrir PowerShell **como administrador** en el repositorio y ejecutar:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Deploy-PoliMusic.ps1 -SqlInstance '.\SQLSERVER2025' -EnableAsp
```

Después abrir `http://localhost/PoliMusic/` y repetir `Test-Integration.ps1` con `-BaseUrl 'http://localhost/PoliMusic/'`. La configuración y los permisos específicos del pool requieren esa validación final.
