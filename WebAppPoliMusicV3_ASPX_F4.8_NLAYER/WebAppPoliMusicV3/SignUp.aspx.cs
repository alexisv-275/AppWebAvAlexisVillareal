using System; using System.Configuration; using System.Globalization; using System.IO; using System.Text.RegularExpressions;
namespace WebAppPoliMusicV3 { public partial class SignUp : System.Web.UI.Page {
 protected void btnSumbit_Click(object sender, EventArgs e) {
  string name=txtUserName.Text.Trim(),email=txtEmail.Text.Trim(),password=txtPassword.Text;
  if(!Regex.IsMatch(name,@"^[a-zA-Z0-9._-]{3,50}$")){lblMessage.Text="El usuario debe tener de 3 a 50 letras, números, puntos, guiones o guiones bajos.";return;}
  if(email.Length>50||!Regex.IsMatch(email,@"^[^@\s]+@[^@\s]+\.[^@\s]+$")){lblMessage.Text="Escribe un correo electrónico válido.";return;}
  if(password.Length<8||password.Length>128){lblMessage.Text="La contraseña debe tener entre 8 y 128 caracteres.";return;}
  if(password!=txtConfirmPassword.Text){lblMessage.Text="Las contraseñas no coinciden.";return;}
  string birthday=""; DateTime date;
  if(!string.IsNullOrWhiteSpace(txtBirthDate.Text)){
   if(!DateTime.TryParseExact(txtBirthDate.Text.Trim(),"dd/MM/yyyy",CultureInfo.InvariantCulture,DateTimeStyles.None,out date)||date<DateTime.Parse("1753-01-01",CultureInfo.InvariantCulture)||date>DateTime.Today){lblMessage.Text="Escribe una fecha válida en formato dd/MM/yyyy, no futura.";return;} birthday=date.ToString("yyyy-MM-dd");
  }
  string photoFile=null;
  try{
   var bll=new BLL.PoliMusicV3.User(ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString);
   var user=new EntityLayer.PoliMusicV3.User(0,name,EntityLayer.PoliMusicV3.Util.Hash.GeneratePasswordHash(password),email,birthday,0,"~/UserImages/default.jpg");
   string duplicate=bll.ValidationsDuplicated(user); if(duplicate!=""){lblMessage.Text=duplicate;return;}
   if(fupPhoto.HasFile){
    string ext=Path.GetExtension(fupPhoto.FileName).ToLowerInvariant();
    if((ext!=".jpg"&&ext!=".jpeg"&&ext!=".png")||fupPhoto.PostedFile.ContentLength>10485760){lblMessage.Text="Selecciona una foto JPG o PNG de hasta 10 MB.";return;}
    using(var img=System.Drawing.Image.FromStream(fupPhoto.PostedFile.InputStream)){
     if(img.Width>6000||img.Height>6000){lblMessage.Text="La foto no debe superar 6000 píxeles por lado.";return;}
     string file=Guid.NewGuid().ToString("N")+".png";photoFile=Server.MapPath("~/UserImages/"+file);img.Save(photoFile,System.Drawing.Imaging.ImageFormat.Png);user.Photo="~/UserImages/"+file;
    }
   }
   bll.Save(user); lblMessage.Text="Cuenta creada correctamente. Ya puedes iniciar sesión.";
  }catch(Exception ex){if(photoFile!=null&&File.Exists(photoFile))File.Delete(photoFile);Trace.Warn("PoliMusic","Error al registrar usuario",ex);lblMessage.Text="No se pudo crear la cuenta. Revisa los datos o intenta nuevamente.";}
 }
} }
