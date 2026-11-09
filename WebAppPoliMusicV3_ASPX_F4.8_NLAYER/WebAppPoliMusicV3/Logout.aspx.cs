using System; using System.Web.Security;
namespace WebAppPoliMusicV3 { public partial class Logout : System.Web.UI.Page {
 protected void Page_Load(object sender,EventArgs e){FormsAuthentication.SignOut();Session.Clear();Session.Abandon();Response.Cache.SetNoStore();Response.Redirect("~/Login",false);Context.ApplicationInstance.CompleteRequest();}
} }
