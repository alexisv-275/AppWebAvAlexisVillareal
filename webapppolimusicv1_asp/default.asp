<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
RequireLogin
Dim command, songs, total, available, songId, index
Set command = NewCommand("SELECT ID_SONG, SONG_NAME, SONG_PATH FROM TBL_SONG ORDER BY SONG_NAME, ID_SONG")
Set songs = Rows(command)
total = 0
If Not songs.EOF Then
    Dim songData
    songData = songs.GetRows()
    total = UBound(songData, 2) + 1
End If
songs.Close
PageStart "Descubrir"
Header
%>
<main id="main" class="container catalog">
    <section class="hero"><div class="hero-copy"><span class="eyebrow"><span class="little-line"></span> DALE PLAY A TU DÍA</span><h1>Encuentra tu<br><span>próximo ritmo.</span></h1><p>Una pausa, una canción, un momento para ti.<br>Explora tu biblioteca y deja que la música haga el resto.</p><a class="button" href="#songs">Explorar canciones <span aria-hidden="true">↓</span></a></div><div class="hero-art" aria-hidden="true"><span class="orbit orbit-one"></span><span class="orbit orbit-two"></span><span class="art-caption">GOOD MUSIC.<br>GOOD MOMENTS.</span><div class="record"><span>poli<br>music.</span></div><span class="art-star">✳</span><span class="art-note">♪</span></div></section>
    <section id="songs" aria-labelledby="song-heading"><div class="section-heading"><div><span class="eyebrow">TU BIBLIOTECA</span><h2 id="song-heading">Listado de canciones<span class="count"><%=total%></span></h2></div><span class="section-note">Elige una canción. Disfruta el momento.</span></div>
    <% If total = 0 Then %><div class="empty-state"><h3>Todo empieza con una canción.</h3><p>Aún no hay canciones en la biblioteca.<% If IsAdmin() Then %> Añade la primera desde administración.<% End If %></p><% If IsAdmin() Then %><a class="button" href="song-edit.asp">Añadir canción</a><% End If %></div><% Else %>
    <div class="song-grid">
    <% For index = 0 To total - 1
        songId = CLng(songData(0, index))
        available = SongAvailable(songData(2, index))
    %>
        <article class="song-card" data-song-card="<%=songId%>">
            <div class="song-art tone-<%=(index Mod 4)%>" aria-hidden="true"><span class="art-small">POLIMUSIC / AUDIO</span><div class="mini-record"><i></i></div><span class="art-number"><%=Right("0" & (index + 1), 2)%></span><span class="art-label">ENCUENTRA TU RITMO</span></div>
            <div class="song-info"><div><h3><%=H(songData(1, index))%></h3><p class="song-status"><% If available Then %>Lista para escuchar<% Else %>Audio no disponible<% End If %></p></div><button type="button" class="play-button" data-song-id="<%=songId%>" data-song-name="<%=H(songData(1, index))%>" data-audio-url="<%=H(AppUrl("audio.asp?id=" & songId))%>" aria-label="Reproducir <%=H(songData(1, index))%>" <% If Not available Then %>disabled<% End If %>><span aria-hidden="true">▶</span></button></div>
        </article>
    <% Next %>
    </div><% End If %>
    </section><footer class="catalog-footer"><span>PoliMusic<span class="brand-dot">.</span></span><span>La música hace bien.</span></footer>
</main>
<section class="player" aria-label="Reproductor de música"><div class="player-inner"><div class="player-track"><div class="player-icon" aria-hidden="true">♫</div><div><span class="eyebrow" id="player-state">AHORA SUENA</span><h2 id="player-title">Selecciona una canción</h2></div></div><audio id="audio-player" controls preload="none" aria-label="Controles de reproducción"></audio><span class="player-message" id="player-message" role="status" aria-live="polite">Tu momento empieza aquí.</span></div></section>
<noscript><p class="notice">Activa JavaScript para seleccionar canciones en el reproductor.</p></noscript>
<% PageEnd %>
