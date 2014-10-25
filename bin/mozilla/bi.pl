#=================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# business intelligence
#
#======================================================================

#use strict; use warnings;
use SL::Form;
use SL::User;
use SL::BI;
use HTML::Entities; 
use JSON;

require "$form->{path}/tt.pl";

1;
# end of main

sub add { &{ "add_".$form->{type} } }
sub save { &{ "save_".$form->{type} } }
sub get { &{ "get_".$form->{type} } }

sub display {

  $form->{title} = $locale->text("dashboard");
  $form->{viewfile} = $views."/bi.pl_dashboard.tt";
  $form->{texts} = $locale->all_texts();
  %{$form->{myconfig}} = %myconfig;
  $form->{customheader} = "<script type='text/javascript' src='https://www.google.com/jsapi'></script>\n";

  render($form);
  exit;
}

# get available KPIs 
sub get_dash {

  my $d = new DASH ( \%myconfig, $form, undef );
  $d->init();

  $form->{json} = 1;
  $form->header();
  print encode_json $d->dash();

  exit;
}

sub timeframe {

  my $dash = new DASH ( \%myconfig, $form, undef );

  $form->{json} = 1;
  $form->header();
  print encode_json $dash->timeframe();

  exit;
}

# get KPI data
sub get_kpi {

  my $dash = new DASH ( \%myconfig, $form, undef );
  $kpis = $dash->init();

  my $kpi = new KPI ( \%myconfig, $form, undef );

# get key figure data on google chart structure
  my $kf = $kpi->keyfigure($kpis->{$form->{kpi}});

  $form->{json} = 1;
  $form->header();
  print encode_json($kf);

  exit;
}

#
#  EOF
1;
