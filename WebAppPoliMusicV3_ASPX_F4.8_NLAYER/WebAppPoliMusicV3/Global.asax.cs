using System;
using System.Web;
using System.Web.Routing;
using Microsoft.AspNet.FriendlyUrls;

namespace WebAppPoliMusicV3
{
    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            RouteTable.Routes.EnableFriendlyUrls(new FriendlyUrlSettings
            {
                AutoRedirectMode = RedirectMode.Off
            });
        }
    }
}
