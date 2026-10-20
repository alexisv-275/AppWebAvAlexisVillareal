<%
Option Explicit
Response.CodePage = 65001
Response.Charset = "utf-8"
Response.Buffer = True
Response.Expires = -1
Response.CacheControl = "no-cache"
Response.AddHeader "Cache-Control", "no-store, private, max-age=0"
Response.AddHeader "Pragma", "no-cache"
Response.AddHeader "X-Content-Type-Options", "nosniff"
Response.AddHeader "X-Frame-Options", "DENY"
Response.AddHeader "Referrer-Policy", "same-origin"
Response.AddHeader "Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; media-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"
Session.Timeout = 20

Const ConnectionFile = "C:\ProgramData\PoliMusic\connection.txt"
Const MediaFolder = "SongFilesAndImages_resources/SongFiles/"
Dim db
Set db = Nothing

Function H(value)
    H = Server.HTMLEncode(CStr(value & ""))
End Function

Function AppUrl(relativePath)
    Dim scriptPath
    scriptPath = Request.ServerVariables("SCRIPT_NAME")
    AppUrl = Left(scriptPath, InStrRev(scriptPath, "/")) & relativePath
End Function

Sub Fail(statusCode, message)
    Response.Status = statusCode
    Response.Write "<!doctype html><html lang=""es""><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width,initial-scale=1""><title>PoliMusic</title><link rel=""stylesheet"" href=""" & H(AppUrl("assets/styles.css")) & """><main class=""error-page""><h1>PoliMusic</h1><p role=""alert"">" & H(message) & "</p><a class=""button"" href=""" & H(AppUrl("default.asp")) & """>Volver al inicio</a></main></html>"
    Response.End
End Sub

Sub OpenDb()
    Dim fso, file, connectionString, failed
    If Not (db Is Nothing) Then Exit Sub
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If Not fso.FileExists(ConnectionFile) Then Fail "503 Service Unavailable", "Falta configurar la conexión de PoliMusic. Consulta la guía de instalación."
    On Error Resume Next
    Set file = fso.OpenTextFile(ConnectionFile, 1, False)
    connectionString = Trim(file.ReadAll)
    file.Close
    Set db = Server.CreateObject("ADODB.Connection")
    db.ConnectionTimeout = 5
    db.CommandTimeout = 15
    db.Open connectionString
    failed = (Err.Number <> 0)
    Err.Clear
    On Error GoTo 0
    If failed Then Fail "503 Service Unavailable", "No se pudo conectar con la base de datos. Inténtalo más tarde."
End Sub

Function NewCommand(sql)
    OpenDb
    Dim command
    Set command = Server.CreateObject("ADODB.Command")
    Set command.ActiveConnection = db
    command.CommandType = 1
    command.CommandTimeout = 15
    command.CommandText = sql
    Set NewCommand = command
End Function

Sub AddText(command, value, maxLength)
    command.Parameters.Append command.CreateParameter("", 200, 1, maxLength, value)
End Sub

Sub AddInt(command, value)
    command.Parameters.Append command.CreateParameter("", 3, 1, , CLng(value))
End Sub

Function Rows(command)
    Dim result, failed
    On Error Resume Next
    Set result = command.Execute
    failed = (Err.Number <> 0)
    Err.Clear
    On Error GoTo 0
    If failed Then Fail "503 Service Unavailable", "No se pudo consultar el catálogo. Inténtalo más tarde."
    Set Rows = result
End Function

Function PositiveId(value)
    Dim regex
    PositiveId = 0
    Set regex = New RegExp
    regex.Pattern = "^[1-9][0-9]{0,9}$"
    If Not regex.Test(CStr(value)) Then Exit Function
    If CDbl(value) > 2147483647 Then Exit Function
    PositiveId = CLng(value)
End Function

Function LoggedIn()
    LoggedIn = False
    If PositiveId(Session("ID_USER") & "") = 0 Then Exit Function
    If Len(Session("USERNAME") & "") = 0 Then Exit Function
    If CStr(Session("USER_TYPE")) <> "0" And CStr(Session("USER_TYPE")) <> "1" Then Exit Function
    LoggedIn = True
End Function

Function IsAdmin()
    IsAdmin = LoggedIn() And CStr(Session("USER_TYPE")) = "1"
End Function

Sub RequireLogin()
    If Not LoggedIn() Then
        Response.Redirect AppUrl("login.asp")
        Response.End
    End If
End Sub

Sub RequireAdmin()
    RequireLogin
    If Not IsAdmin() Then Fail "403 Forbidden", "Esta sección está disponible únicamente para administradores."
End Sub

Function Token()
    Dim command, result
    If Len(Session("CSRF") & "") = 0 Then
        Set command = NewCommand("SELECT CONVERT(varchar(64), CRYPT_GEN_RANDOM(32), 2) AS TOKEN")
        Set result = Rows(command)
        Session("CSRF") = CStr(result("TOKEN"))
        result.Close
    End If
    Token = Session("CSRF")
End Function

Sub CheckPost()
    If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
        Response.AddHeader "Allow", "POST"
        Fail "405 Method Not Allowed", "Esta acción requiere enviar el formulario."
    End If
    If Len(Session("CSRF") & "") <> 64 Then Fail "403 Forbidden", "El formulario ha vencido. Vuelve a abrir la página."
    If StrComp(CStr(Request.Form("csrf")), CStr(Session("CSRF")), 0) <> 0 Then Fail "403 Forbidden", "El formulario no es válido. Vuelve a abrir la página."
End Sub

Function SongFilename(storedPath)
    Dim value, prefix, name, regex
    SongFilename = ""
    value = CStr(storedPath & "")
    prefix = "~/songFiles/"
    If LCase(Left(value, Len(prefix))) = LCase(prefix) Then
        name = Mid(value, Len(prefix) + 1)
    ElseIf LCase(Left(value, Len(MediaFolder))) = LCase(MediaFolder) Then
        name = Mid(value, Len(MediaFolder) + 1)
    Else
        Exit Function
    End If
    Set regex = New RegExp
    regex.Pattern = "^[a-zA-Z0-9][a-zA-Z0-9 _().-]*\.mp3$"
    regex.IgnoreCase = True
    If Not regex.Test(name) Then Exit Function
    If InStr(name, "..") > 0 Then Exit Function
    SongFilename = name
End Function

Function SongAvailable(storedPath)
    Dim fso, name
    SongAvailable = False
    name = SongFilename(storedPath)
    If name = "" Then Exit Function
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    SongAvailable = fso.FileExists(Server.MapPath(MediaFolder & name))
End Function

Function UserPhoto()
    Dim photo, fso
    photo = Session("USER_PHOTO") & ""
    If LCase(photo) = "~/userimages/root.png" Then
        photo = "root.png"
    Else
        photo = "default.jpg"
    End If
    UserPhoto = AppUrl("SongFilesAndImages_resources/UserImages/" & photo)
End Function

Sub PageStart(title)
%>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#FAF7F2">
    <title><%=H(title)%> · PoliMusic</title>
    <link rel="icon" href="<%=H(AppUrl("assets/mark.svg"))%>" type="image/svg+xml">
    <link rel="stylesheet" href="<%=H(AppUrl("assets/styles.css"))%>">
    <script src="<%=H(AppUrl("assets/app.js"))%>" defer></script>
</head>
<body>
<a class="skip-link" href="#main">Saltar al contenido</a>
<%
End Sub

Sub Brand()
%>
<a class="brand" href="<%=H(AppUrl("default.asp"))%>" aria-label="PoliMusic, inicio"><img src="<%=H(AppUrl("assets/mark.svg"))%>" width="40" height="40" alt="">Poli<span>Music</span><span class="brand-dot">.</span></a>
<%
End Sub

Sub Header()
    Dim csrf
    csrf = Token()
%>
<header class="site-header"><div class="header-inner">
<% Brand %>
<nav aria-label="Navegación principal"><a href="<%=H(AppUrl("default.asp"))%>" class="nav-link">Descubrir</a><% If IsAdmin() Then %><a href="<%=H(AppUrl("admin.asp"))%>" class="nav-link">Administrar canciones</a><% End If %></nav>
<div class="account"><img class="avatar" src="<%=H(UserPhoto())%>" width="40" height="40" alt=""><div><span class="welcome">Bienvenido, <strong><%=H(Session("USERNAME"))%></strong></span><span class="role"><% If IsAdmin() Then %>Administrador<% Else %>Usuario<% End If %></span></div><form action="<%=H(AppUrl("logout.asp"))%>" method="post"><input type="hidden" name="csrf" value="<%=H(csrf)%>"><button class="button-quiet" type="submit">Cerrar sesión</button></form></div>
</div></header>
<%
End Sub

Sub PageEnd()
    If Not (db Is Nothing) Then
        If db.State = 1 Then db.Close
    End If
    Set db = Nothing
%>
</body></html>
<%
End Sub
%>
