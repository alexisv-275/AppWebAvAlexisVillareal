<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
RequireAdmin
Dim songId, command, song, songName, songPath, errorMessage, csrf, fso, folder, file, optionPath, filesAvailable, failed, selectedPath, editing, rawId
songName = ""
songPath = ""
errorMessage = ""
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    CheckPost
    rawId = Request.Form("id") & ""
Else
    rawId = Request.QueryString("id") & ""
End If
songId = PositiveId(rawId)
If rawId <> "" And songId = 0 Then Fail "400 Bad Request", "El identificador de canción no es válido."
editing = (songId > 0)
If editing Then
    Set command = NewCommand("SELECT SONG_NAME, SONG_PATH FROM TBL_SONG WHERE ID_SONG = ?")
    AddInt command, songId
    Set song = Rows(command)
    If song.EOF Then Fail "404 Not Found", "La canción ya no existe."
    songName = song("SONG_NAME") & ""
    songPath = song("SONG_PATH") & ""
    song.Close
End If
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    songName = Trim(Request.Form("song_name"))
    selectedPath = Request.Form("song_path") & ""
    If Len(songName) = 0 Or Len(songName) > 50 Then
        errorMessage = "Escribe un nombre de entre 1 y 50 caracteres."
    ElseIf Len(selectedPath) > 255 Or Not SongAvailable(selectedPath) Then
        errorMessage = "Selecciona un archivo MP3 disponible en la carpeta del servidor."
    Else
        songPath = "~/songFiles/" & SongFilename(selectedPath)
        If editing Then
            Set command = NewCommand("UPDATE TBL_SONG SET SONG_NAME = ?, SONG_PATH = ? WHERE ID_SONG = ?")
        Else
            Set command = NewCommand("INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, 0)")
        End If
        AddText command, songName, 50
        AddText command, songPath, 255
        If editing Then AddInt command, songId
        On Error Resume Next
        command.Execute , , 128
        failed = (Err.Number <> 0)
        Err.Clear
        On Error GoTo 0
        If failed Then
            errorMessage = "No se pudo guardar la canción. Inténtalo de nuevo."
        Else
            Response.Redirect AppUrl("admin.asp?saved=1")
        End If
    End If
End If
csrf = Token()
Set fso = Server.CreateObject("Scripting.FileSystemObject")
filesAvailable = 0
If editing Then
    PageStart "Editar canción"
Else
    PageStart "Añadir canción"
End If
Header
%>
<main id="main" class="container admin-main"><a class="back-link" href="admin.asp">← Volver a administración</a><section class="editor-panel"><span class="eyebrow">TU BIBLIOTECA, A TU MANERA</span><h1><% If editing Then %>Editar canción<% Else %>Añadir canción<% End If %></h1><p>Un nombre y un archivo. Así empieza un nuevo ritmo.</p>
<% If errorMessage <> "" Then %><p class="notice error" role="alert"><%=H(errorMessage)%></p><% End If %>
<form method="post" action="song-edit.asp" class="stack"><input type="hidden" name="csrf" value="<%=H(csrf)%>"><input type="hidden" name="id" value="<% If editing Then %><%=songId%><% End If %>">
<label for="song_name">Nombre de la canción</label><input id="song_name" name="song_name" maxlength="50" required value="<%=H(songName)%>" aria-describedby="name-help"><small id="name-help">Hasta 50 caracteres.</small>
<label for="song_path">Archivo MP3</label><select id="song_path" name="song_path" required aria-describedby="path-help"><option value="">Selecciona un archivo disponible</option>
<% If fso.FolderExists(Server.MapPath(MediaFolder)) Then
    Set folder = fso.GetFolder(Server.MapPath(MediaFolder))
    For Each file In folder.Files
        optionPath = "~/songFiles/" & file.Name
        If SongFilename(optionPath) <> "" And Len(optionPath) <= 255 Then
            filesAvailable = filesAvailable + 1
%><option value="<%=H(optionPath)%>" <% If LCase(SongFilename(songPath)) = LCase(file.Name) Then %>selected<% End If %>><%=H(file.Name)%></option><%
        End If
    Next
End If %>
</select><small id="path-help">Solo se muestran MP3 locales disponibles. Para incorporar más archivos, cópialos a SongFilesAndImages_resources/SongFiles.</small>
<% If editing And Not SongAvailable(songPath) Then %><p class="notice">El archivo anterior no está disponible: <%=H(songPath)%>. Selecciona un MP3 existente para guardar.</p><% End If %>
<% If filesAvailable = 0 Then %><p class="notice error">No hay archivos MP3 disponibles. Copia uno a la carpeta indicada antes de guardar.</p><% End If %>
<div class="form-actions"><button class="button" type="submit" <% If filesAvailable = 0 Then %>disabled<% End If %>>Guardar canción</button><a class="button button-secondary" href="admin.asp">Cancelar</a></div></form></section></main>
<% PageEnd %>
