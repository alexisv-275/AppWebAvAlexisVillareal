<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
Dim errorMessage, username, password, command, users, csrf, encoded
If LoggedIn() Then Response.Redirect AppUrl("default.asp")
errorMessage = ""
username = ""
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    CheckPost
    username = Trim(Request.Form("username"))
    password = Request.Form("password")
    If Len(username) = 0 Or Len(username) > 50 Or Len(password) = 0 Or Len(password) > 50 Then
        errorMessage = "Introduce un usuario y una contraseña válidos."
    Else
        Set command = NewCommand("SELECT ID_USER, USERNAME, [PASSWORD], USER_TYPE, USER_PHOTO FROM TBL_USER WHERE USERNAME = ?")
        AddText command, username, 50
        Set users = Rows(command)
        If Not users.EOF Then
            Set encoded = New RegExp
            encoded.Pattern = "^[a-fA-F0-9]{32,}$"
            If Not encoded.Test(CStr(users("PASSWORD"))) And StrComp(password, CStr(users("PASSWORD")), 0) = 0 Then
                If CStr(users("USER_TYPE")) = "0" Or CStr(users("USER_TYPE")) = "1" Then
                    Session.Contents.RemoveAll
                    Session("ID_USER") = CLng(users("ID_USER"))
                    Session("USERNAME") = CStr(users("USERNAME"))
                    Session("USER_TYPE") = CInt(users("USER_TYPE"))
                    Session("USER_PHOTO") = users("USER_PHOTO") & ""
                    users.Close
                    db.Close
                    Response.Redirect AppUrl("default.asp")
                End If
            End If
        End If
        users.Close
        errorMessage = "Usuario o contraseña incorrectos."
    End If
End If
csrf = Token()
PageStart "Iniciar sesión"
%>
<main id="main" class="login-layout">
    <section class="login-story"><% Brand %><span class="eyebrow">TU PAUSA. TU RITMO.</span><h1>Un buen día<br>empieza con<br><span>una canción.</span></h1><p>Un espacio para desconectar, descubrir y darle play a lo que te mueve.</p><div class="record-scene" aria-hidden="true"><div class="record"><span>poli<br>music.</span></div><div class="sound-waves"><i></i><i></i><i></i><i></i><i></i></div></div><span class="story-footer">HECHO PARA ESCUCHAR, A TU MANERA.</span></section>
    <section class="login-side"><div class="login-card"><span class="eyebrow">BIENVENIDO A POLIMUSIC</span><h2>Tu música te espera.</h2><p>Inicia sesión para entrar a tu espacio musical.</p>
    <% If errorMessage <> "" Then %><div class="notice error" role="alert"><%=H(errorMessage)%></div><% End If %>
    <form method="post" action="login.asp" class="stack">
        <input type="hidden" name="csrf" value="<%=H(csrf)%>">
        <label for="username">Usuario</label><input id="username" name="username" autocomplete="username" required maxlength="50" value="<%=H(username)%>" placeholder="Tu nombre de usuario">
        <label for="password">Contraseña</label><input id="password" type="password" name="password" autocomplete="current-password" required maxlength="50" placeholder="Tu contraseña">
        <button class="button button-wide" type="submit">Entrar a PoliMusic <span aria-hidden="true">↗</span></button>
    </form><p class="form-note">Tu biblioteca, a un play de distancia.</p></div><p class="login-footer">PoliMusic · Cada día tiene su propio ritmo.</p></section>
</main>
<% PageEnd %>
