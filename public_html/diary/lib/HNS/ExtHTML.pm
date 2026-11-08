# $Id: ExtHTML.pm,v 1.5 2001/04/14 23:32:01 kenji Exp $
package HNS::ExtHTML;

use strict;
use vars qw($DOCTYPE $Head $Head_recent $BodyVal $DynamicPrintFunc);
use vars qw(%HEAD %Head_recent);

$DOCTYPE = qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/REC-html40/loose.dtd">\n);

$Head = qq(<meta http-equiv="Content-Style-Type" content="text/css">
<style type="text/css"><!--
 body { background: white }
 h3.new { margin-left: 1em }
 div.uservar { font-weight: bold; }
 div.section { margin-left: 2em; margin-top: 0 }
 div.sub { margin-left: 1em; margin-top: 0 }
 div.list { margin-left: 1em }
 div.fn { margin-left: 1em; margin-top: 0 }
 div.url { margin-bottom: 0 }
 pre {
  white-space:  pre;
  padding:      0.5em;
  border-color: #ffeeb0;
  border-style: outset;
  border-width: 4px
 }
 a.hide:link { color: black; text-decoration: none }
 span.bold-red { color: red; font-weight: bold }
 div.bold-red { color: red; font-weight: bold }
--></style>
);

$BodyVal = undef;

$DynamicPrintFunc = undef;

1;
