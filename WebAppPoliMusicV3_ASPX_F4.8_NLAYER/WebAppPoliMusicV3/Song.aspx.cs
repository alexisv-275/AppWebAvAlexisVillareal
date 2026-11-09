using System; using System.Configuration; using System.Data; using System.IO; using System.Web; using System.Web.UI.WebControls;
namespace WebAppPoliMusicV3 {
 public partial class Song : System.Web.UI.Page {
  protected void Page_Load(object sender, EventArgs e) {
   if(!IsPostBack) { try {
    var songs=new BLL.PoliMusicV3.Song(ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString).Read();
    songCount.Text=songs.Rows.Count.ToString(); gvSongs.DataSource=songs; gvSongs.DataBind();
    if(gvSongs.HeaderRow!=null) gvSongs.HeaderRow.TableSection=TableRowSection.TableHeader;
   } catch(Exception ex) { Trace.Warn("PoliMusic", "Error consultando canciones", ex); songCount.Text="0"; lblMessage.Text="No se pudo cargar el catálogo. Intenta nuevamente en unos momentos."; } }
  }
  protected void Songs_RowDataBound(object sender, GridViewRowEventArgs e) {
   if(e.Row.RowType!=DataControlRowType.DataRow) return;
   var row=(DataRowView)e.Row.DataItem; var player=(Literal)e.Row.FindControl("player");
   string stored=Convert.ToString(row["SONG_PATH"]).Replace('\\','/');
   string file=Path.GetFileName(stored);
   if(string.IsNullOrWhiteSpace(file) || !file.EndsWith(".mp3",StringComparison.OrdinalIgnoreCase) || !File.Exists(Server.MapPath("~/SongFiles/"+file))) { player.Text="<span class='unavailable'>Audio no disponible</span>"; return; }
   string url=ResolveUrl("~/SongFiles/"+Uri.EscapeDataString(file));
   player.Text="<audio controls preload='none' aria-label='Reproducir "+HttpUtility.HtmlAttributeEncode(Convert.ToString(row["SONG_NAME"]))+"'><source src='"+HttpUtility.HtmlAttributeEncode(url)+"' type='audio/mpeg'/>Tu navegador no admite audio HTML5.</audio>";
  }
 }
}
