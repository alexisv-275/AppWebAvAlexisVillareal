using System;
namespace WebAppPoliMusicV3 { public partial class Default : System.Web.UI.Page {
 protected void Page_Load(object sender, EventArgs e) { var user=Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User; if(user!=null) userName.Text=user.UserName; }
} }
