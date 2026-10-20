<%@ Language=VBScript CodePage=65001 %>
<!--#include file="includes/common.asp"-->
<%
RequireLogin
CheckPost
Session.Contents.RemoveAll
Session.Abandon
Response.Redirect AppUrl("login.asp")
%>
