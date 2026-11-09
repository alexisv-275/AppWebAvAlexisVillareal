using System; using System.Web; using System.Web.Security;
namespace WebAppPoliMusicV3 { public partial class SiteMaster : System.Web.UI.MasterPage {
 protected void Page_Load(object sender, EventArgs e) {
  Response.Cache.SetCacheability(HttpCacheability.NoCache); Response.Cache.SetNoStore();
  if (Session[EntityLayer.PoliMusicV3.Util.Constants.USER] == null) {
   FormsAuthentication.SignOut(); Response.Redirect("~/Login", false); Context.ApplicationInstance.CompleteRequest();
  }
 }
} }
