<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
RequireAdmin
Dim songId, command, song, songName, links, csrf, transactionFailed, affected, statement, statements, errorMessage
errorMessage = ""
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    CheckPost
    songId = PositiveId(Request.Form("id"))
Else
    songId = PositiveId(Request.QueryString("id"))
End If
If songId = 0 Then Fail "400 Bad Request", "El identificador de canción no es válido."
Set command = NewCommand("SELECT SONG_NAME, (SELECT COUNT(*) FROM TBL_TRACKLIST WHERE ID_SONG = s.ID_SONG) AS ALBUMS, (SELECT COUNT(*) FROM TBL_PLAYER WHERE ID_SONG = s.ID_SONG) AS ARTISTS, (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_SONG = s.ID_SONG) AS PLAYLISTS FROM TBL_SONG s WHERE ID_SONG = ?")
AddInt command, songId
Set song = Rows(command)
If song.EOF Then Fail "404 Not Found", "La canción ya no existe."
songName = song("SONG_NAME") & ""
links = "Álbumes: " & song("ALBUMS") & " · Artistas: " & song("ARTISTS") & " · Playlists: " & song("PLAYLISTS")
song.Close
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    statements = Array("DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?", "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?", "DELETE FROM TBL_SONG WHERE ID_SONG = ?")
    transactionFailed = False
    On Error Resume Next
    db.BeginTrans
    If Err.Number <> 0 Then transactionFailed = True
    Err.Clear
    For Each statement In statements
        If Not transactionFailed Then
            Set command = NewCommand(statement)
            AddInt command, songId
            command.Execute , , 128
            If Err.Number <> 0 Then transactionFailed = True
            Err.Clear
        End If
    Next
    If Not transactionFailed Then
        db.CommitTrans
        If Err.Number <> 0 Then transactionFailed = True
        Err.Clear
    End If
    If transactionFailed Then db.RollbackTrans
    Err.Clear
    On Error GoTo 0
    If transactionFailed Then
        errorMessage = "No se pudo eliminar la canción. No se guardaron cambios parciales."
    Else
        Response.Redirect AppUrl("admin.asp?deleted=1")
    End If
End If
csrf = Token()
PageStart "Eliminar canción"
Header
%>
<main id="main" class="container admin-main"><a class="back-link" href="admin.asp">← Volver a administración</a><section class="editor-panel"><span class="eyebrow">CONFIRMA LA ELIMINACIÓN</span><h1>¿Eliminar esta canción?</h1><p>Vas a eliminar <strong><%=H(songName)%></strong> de la biblioteca.</p><div class="notice"><p>También se retirará de sus asociaciones existentes:</p><p><strong><%=H(links)%></strong></p><p>Se conservarán los álbumes, artistas, playlists y el archivo MP3.</p></div>
<% If errorMessage <> "" Then %><p class="notice error" role="alert"><%=H(errorMessage)%></p><% End If %>
<form method="post" action="song-delete.asp"><input type="hidden" name="csrf" value="<%=H(csrf)%>"><input type="hidden" name="id" value="<%=songId%>"><div class="form-actions"><button class="button button-danger" type="submit">Sí, eliminar canción</button><a class="button button-secondary" href="admin.asp">Cancelar</a></div></form></section></main>
<% PageEnd %>
