using System; using System.Configuration; using System.Data; using System.Web.Security;
namespace WebAppPoliMusicV3 { public partial class Login : System.Web.UI.Page {
 protected void BtnLogin_Click(object sender, EventArgs e) {
  if(string.IsNullOrWhiteSpace(txtLogin.Text)||string.IsNullOrEmpty(txtPassword.Text)){lblMessage.Text="Escribe tu usuario y contraseña.";return;}
  try {
   string hash=EntityLayer.PoliMusicV3.Util.Hash.GeneratePasswordHash(txtPassword.Text);
   var dt=new BLL.PoliMusicV3.User(ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString).AuthenticateUser(txtLogin.Text.Trim(),hash);
   if(dt.Rows.Count==0){lblMessage.Text="Usuario o contraseña incorrectos.";return;}
   var r=dt.Rows[0]; int type=Convert.ToInt32(r["USER_TYPE"]);
   if(type!=0 && type!=1){lblMessage.Text="Usuario o contraseña incorrectos.";return;}
   Session[EntityLayer.PoliMusicV3.Util.Constants.USER]=new EntityLayer.PoliMusicV3.User(Convert.ToInt32(r["ID_USER"]),Convert.ToString(r["USERNAME"]),null,Convert.ToString(r["EMAIL"]),Convert.ToString(r["BIRTHDAY"]),type,Convert.ToString(r["USER_PHOTO"]));
   FormsAuthentication.SetAuthCookie(Convert.ToString(r["USERNAME"]),false);
   Response.Redirect("~/Default",false);Context.ApplicationInstance.CompleteRequest();
  }catch(Exception ex){Trace.Warn("PoliMusic","Error al iniciar sesión",ex);lblMessage.Text="No se pudo iniciar sesión. Comprueba la conexión e intenta nuevamente.";}
 }
} }
