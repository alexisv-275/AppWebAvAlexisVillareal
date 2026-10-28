using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                string connectionString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
                gvSongs.DataSource = new BLL.Song(connectionString).Read();
                gvSongs.DataBind();
            }
        }

        protected void gvSongs_SelectedIndexChanged(object sender, EventArgs e)
        {

        }
    }
}