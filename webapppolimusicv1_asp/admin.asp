<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
RequireAdmin
Dim command, songs, available
Set command = NewCommand("SELECT ID_SONG, SONG_NAME, SONG_PATH, PLAYS FROM TBL_SONG ORDER BY SONG_NAME, ID_SONG")
Set songs = Rows(command)
PageStart "Administrar canciones"
Header
%>
<main id="main" class="container admin-main"><a class="back-link" href="default.asp">← Volver a la biblioteca</a><div class="section-heading"><div><span class="eyebrow">ESPACIO DE ADMINISTRACIÓN</span><h1>Administrar canciones</h1><p>Cuida la biblioteca. Dale lugar a nuevos ritmos.</p></div><a class="button" href="song-edit.asp">＋ Añadir canción</a></div>
<% If Request.QueryString("saved") = "1" Then %><p class="notice success" role="status">Canción guardada correctamente.</p><% End If %>
<% If Request.QueryString("deleted") = "1" Then %><p class="notice success" role="status">Canción y asociaciones eliminadas. El archivo MP3 se conserva.</p><% End If %>
<% If songs.EOF Then %><div class="empty-state"><h2>La biblioteca está por comenzar.</h2><p>Añade tu primera canción seleccionando un MP3 disponible.</p></div><% Else %>
<div class="table-wrap"><table><caption class="sr-only">Canciones de la biblioteca y sus acciones administrativas</caption><thead><tr><th scope="col">Canción</th><th scope="col">Archivo</th><th scope="col">Estado</th><th scope="col">Reproducciones</th><th scope="col">Acciones</th></tr></thead><tbody>
<% Do Until songs.EOF
available = SongAvailable(songs("SONG_PATH"))
%>
<tr><td data-label="Canción"><strong><%=H(songs("SONG_NAME"))%></strong></td><td data-label="Archivo" class="file-cell"><%=H(songs("SONG_PATH"))%></td><td data-label="Estado"><span class="status-pill <% If Not available Then %>status-missing<% End If %>"><% If available Then %>Disponible<% Else %>Sin audio<% End If %></span></td><td data-label="Reproducciones"><% If IsNull(songs("PLAYS")) Then %>0<% Else %><%=H(songs("PLAYS"))%><% End If %></td><td data-label="Acciones"><div class="row-actions"><a href="song-edit.asp?id=<%=CLng(songs("ID_SONG"))%>" aria-label="Editar <%=H(songs("SONG_NAME"))%>">Editar</a><a class="danger-link" href="song-delete.asp?id=<%=CLng(songs("ID_SONG"))%>" aria-label="Eliminar <%=H(songs("SONG_NAME"))%>">Eliminar</a></div></td></tr>
<% songs.MoveNext
Loop %>
</tbody></table></div><% End If
songs.Close %>
<p class="form-note">Los archivos se seleccionan desde la carpeta del servidor. No se suben ni se eliminan archivos desde esta aplicación.</p></main>
<% PageEnd %>
