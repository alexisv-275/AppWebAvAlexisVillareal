<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic | Canciones</title>
    <style type="text/css">
        body { margin: 0; background: #10131c; color: #f4f5f8; font-family: Arial, Helvetica, sans-serif; }
        .page { max-width: 1000px; margin: 0 auto; padding: 48px 20px; }
        .eyebrow { color: #a78bfa; font-size: 12px; font-weight: bold; letter-spacing: 3px; text-transform: uppercase; }
        h1 { margin: 10px 0 8px; font-size: 36px; }
        .subtitle { margin: 0 0 28px; color: #aeb4c2; }
        .song-grid { width: 100%; border-collapse: collapse; overflow: hidden; background: #191e2a; border: 1px solid #2b3242; border-radius: 12px; }
        .song-grid th { padding: 16px; background: #222939; color: #c9c4ff; text-align: left; font-size: 12px; letter-spacing: 1px; text-transform: uppercase; }
        .song-grid td { padding: 16px; border-top: 1px solid #2b3242; vertical-align: middle; }
        .song-grid tr:hover td { background: #1e2534; }
        .song-grid audio { width: 100%; min-width: 220px; max-width: 420px; height: 40px; }
        .empty-message { display: block; padding: 24px; color: #aeb4c2; text-align: center; }
        @media (max-width: 640px) { .page { padding: 32px 12px; } h1 { font-size: 30px; } .song-grid th, .song-grid td { padding: 12px 8px; } .song-grid audio { min-width: 180px; } }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <main class="page">
            <div class="eyebrow">PoliMusic</div>
            <h1>Tu música</h1>
            <p class="subtitle">Explora el catálogo y reproduce tus canciones favoritas.</p>
            <asp:GridView ID="gvSongs" runat="server" AutoGenerateColumns="False" CssClass="song-grid" GridLines="None" EmptyDataText="Todavía no hay canciones disponibles." EmptyDataRowStyle-CssClass="empty-message" OnSelectedIndexChanged="gvSongs_SelectedIndexChanged">
                <Columns>
                    <asp:BoundField DataField="SONG_NAME" HeaderText="Canción" HtmlEncode="True" />
                    <asp:BoundField DataField="PLAYS" HeaderText="Reproducciones" />
                    <asp:TemplateField HeaderText="Escuchar">
                        <ItemTemplate>
                            <audio controls="controls" preload="none">
                                <source src='<%# ResolveUrl(Convert.ToString(Eval("SONG_PATH"))) %>' type="audio/mpeg" />
                                Tu navegador no admite la reproducción de audio.
                            </audio>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </main>
    </form>
</body>
</html>
