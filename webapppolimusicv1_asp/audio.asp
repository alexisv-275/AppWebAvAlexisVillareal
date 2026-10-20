<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
RequireLogin
Dim songId, command, song, path, stream, fileSize, firstByte, lastByte, rangeHeader, parts, remaining, amount, failed, regex
songId = PositiveId(Request.QueryString("id"))
If songId = 0 Then Fail "400 Bad Request", "La canción no es válida."
If Request.ServerVariables("REQUEST_METHOD") <> "GET" And Request.ServerVariables("REQUEST_METHOD") <> "HEAD" Then
    Response.AddHeader "Allow", "GET, HEAD"
    Fail "405 Method Not Allowed", "Método no permitido."
End If
Set command = NewCommand("SELECT SONG_PATH FROM TBL_SONG WHERE ID_SONG = ?")
AddInt command, songId
Set song = Rows(command)
If song.EOF Then Fail "404 Not Found", "No se encontró la canción."
path = song("SONG_PATH") & ""
song.Close
db.Close
Set db = Nothing
If Not SongAvailable(path) Then Fail "404 Not Found", "Audio no disponible."
On Error Resume Next
Set stream = Server.CreateObject("ADODB.Stream")
stream.Type = 1
stream.Open
stream.LoadFromFile Server.MapPath(MediaFolder & SongFilename(path))
failed = (Err.Number <> 0)
Err.Clear
On Error GoTo 0
If failed Then Fail "404 Not Found", "Audio no disponible."
fileSize = stream.Size
firstByte = 0
lastByte = fileSize - 1
rangeHeader = Request.ServerVariables("HTTP_RANGE")
If Len(rangeHeader) > 0 Then
    Set regex = New RegExp
    regex.Pattern = "^bytes=([0-9]{0,12})-([0-9]{0,12})$"
    If Not regex.Test(rangeHeader) Then
        stream.Close
        Response.AddHeader "Content-Range", "bytes */" & fileSize
        Fail "416 Range Not Satisfiable", "El rango de audio no es válido."
    End If
    parts = Split(Mid(rangeHeader, 7), "-")
    If parts(0) = "" And parts(1) = "" Then
        firstByte = fileSize
    ElseIf parts(0) = "" Then
        firstByte = fileSize - CDbl(parts(1))
        If firstByte < 0 Then firstByte = 0
    Else
        firstByte = CDbl(parts(0))
        If parts(1) <> "" Then lastByte = CDbl(parts(1))
        If lastByte >= fileSize Then lastByte = fileSize - 1
    End If
    If firstByte > lastByte Or firstByte >= fileSize Then
        stream.Close
        Response.AddHeader "Content-Range", "bytes */" & fileSize
        Fail "416 Range Not Satisfiable", "El rango de audio no es válido."
    End If
    Response.Status = "206 Partial Content"
    Response.AddHeader "Content-Range", "bytes " & firstByte & "-" & lastByte & "/" & fileSize
End If
Response.Clear
Response.ContentType = "audio/mpeg"
Response.AddHeader "Accept-Ranges", "bytes"
Response.AddHeader "Content-Length", CStr(lastByte - firstByte + 1)
Response.AddHeader "Content-Disposition", "inline"
If Request.ServerVariables("REQUEST_METHOD") = "HEAD" Then
    stream.Close
    Response.End
End If
stream.Position = firstByte
remaining = lastByte - firstByte + 1
Do While remaining > 0 And Response.IsClientConnected
    amount = 65536
    If remaining < amount Then amount = remaining
    Response.BinaryWrite stream.Read(amount)
    Response.Flush
    remaining = remaining - amount
Loop
stream.Close
Response.End
%>
