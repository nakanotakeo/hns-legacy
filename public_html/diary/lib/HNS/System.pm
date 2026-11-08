# $Id: System.pm,v 1.17 2002/03/28 16:04:33 kenji Exp $
package HNS::System;

################################################################
# system variable

$Title  = "HNS: hoge's diary";
$UserMail = 'hoge@example.ne.jp';
$Author = undef;
$MesMail = undef;

$DiaryDir = "../../diary";
$MyDiaryURI = "http://www.example.ne.jp/~hoge/diary/";
$IncludeDir = "./"; 
$HoshinoAntenna = "NG";

$DefaultMax = 5;
$StartYear = 1998;
$Theme = "japanese";

$CookieFlag = "ON";
$AdminCookieFlag = "ON";
$CookieExpires = '+1M';
$NoRedirect = 1;

$CacheDir = "../../diary/cache";
$Caching = 1;
$AllowCacheOnly = 0;
$AutoCacheClear = 1;

$RefererLog = "ON";
$LinkLog = "ON";
$CacheLog = "OFF";
$RefererBATTALog = 0;

$TZ = 9;
$Lang = "ja";
           
$AlwaysReverse = "OFF";
$NewReverse = 0;
$LessOutput = 0;
$StrictCalendarLink = 1;

$ImgWidthMaxSize = 300;
$FNCountStyle = 1;
$isystem = "i";

@antenna = ();

$IntelliSearch = 0;
$Mode = 'auto';

$CategorySelect = "ALL";

# error message
use CGI::Tools;
$ruri = CGI::Tools::Escape($ENV{'REQUEST_URI'});
$Error{404} = qq(Status: 404 Not Found\r
Content-Type: text/html\r
\r
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
The requested URL $ruri was not found on this server.
<hr>
<address>Apache Server at $ENV{'SERVER_NAME'} Port $ENV{'SERVER_PORT'}</address>
</body></html>
);

$Error{403} = qq(Status: 403 Forbidden\r
Content-Type: text/html\r
\r
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>403 Forbidden</title>
</head><body>
<h1>Forbidden</h1>
You don't have permission to access $ruri
on this server.
<hr>
<address>Apache Server at $ENV{'SERVER_NAME'} Port $ENV{'SERVER_PORT'}</address>
</body></html>
);

1;
