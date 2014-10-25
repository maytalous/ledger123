#=================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Template Toolkit
#
#######################################################################

# any custom scripts for this one
if (-f "$form->{path}/custom_tt.pl") {
  eval { require "$form->{path}/custom_tt.pl"; };
}
if (-f "$form->{path}/$form->{login}_tt.pl") {
  eval { require "$form->{path}/$form->{login}_tt.pl"; };
}


1;
# end of main

use Template;
use constant DEBUGGING => 0;;
use Switch;

sub render {
  my ($data, $contenttype, $nocookie) = @_;
  my $t = Template->new({
      RELATIVE => 1,
    });

  $contenttype = 'html';
  my $charset = '';

  switch($contenttype) {
    case 'html' {$contenttype = 'Content-Type: text/html;';}
    else 		{$contenttype = 'Content-Type: text/html;';}
  }

  if ($data->{stylesheet} && (-f "css/$data->{stylesheet}")) {
    $data->{stylesheet} = qq|<LINK REL="stylesheet" HREF="css/$data->{stylesheet}" TYPE="text/css" TITLE="WAM stylesheet">|;
  }

  if ($data->{favicon} && (-f "$data->{favicon}")) {
    $data->{favicon} = qq|<LINK REL="icon" HREF="$data->{favicon}" TYPE="image/x-icon">
    <LINK REL="shortcut icon" HREF="$self->{favicon}" TYPE="image/x-icon">|;
  }

  if ($data->{charset}) {
    $charset = "charset = ".$data->{charset};
    $data->{charset} = qq|<META charset="$data->{charset}">|;
  }

  $data->{titlebar} = ($data->{title}) ? "$data->{title} - $data->{titlebar}" : $data->{titlebar};

  $data->set_cookie($endsession) unless $nocookie;

  my ($controller, $null) = split ('.p', $data->{script});
  if (-e "js/$controller.js") {
    $data->{customheader} .= qq|<script type="text/javascript" src='js/|.$controller.qq|.js'></script>\n|;
  }

  my $tfile = qq|$data->{viewfile}|;
  if (DEBUGGING) {
    use Data::Dumper;
    use HTML::Entities;
    $data->{dump} = "<pre>".HTML::Entities::encode_entities( Dumper($data) )."</pre>";
  }

  # output type
  if(!$data->{header}){
    print qq|$contenttype $charset

    |;
  }

  delete $data->{sessioncookie};
 
  # template $tfile includes header.tt and footer.tt 
  $t->process($tfile, $data) or die $t->error();
  return;
}
