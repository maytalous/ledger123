#=================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# Business intelligence
#======================================================================

package DASH;

use parent 'Object::Accessor';
use Switch;

sub new {
  my ($class, $myconfig, $form, $dbh) = @_;
  my $self = {};
  
  $self->{form} = $form;
  $self->{myconfig} = $myconfig;
  $self->{dbh} = $dbh;

  $self->{kpis} = {};

  bless $self, $class;

  #$self->mk_accessors();

  return $self;
}


#init configuration
sub init {
  my( $self ) = @_;

  my $initialconfig = {
    '100sales' => {"id" => "sales", "source" => "100sales", "title" => "Sales",
      charttype => { 
        id => "",                #dinamically set by viewer
        class => "widgetType",   #dinamically set by viewer
        options => [ 
          { id => "column", label => "Column" },
          { id => "line", label => "Line" }, 
          { id => "table", label => "Table" }
        ],
      },
      charcolumns => [0], #characteristics columns, type = string
      kfcolumns => [1],   #key figure columns, type = number
      masterdata => '',
      query => "
      SELECT  to_char(ar.transdate, 'YYYY')||to_char(ar.transdate, 'MM') rowkey,
      ROUND(SUM(ar.netamount)) as total
      FROM ar
      WHERE approved = TRUE
      GROUP BY 1
      ORDER BY 1 DESC
      ",
    },
    '400sales_customer' => {"id" => "salescustomer", "source" => "400sales_customer", "title" => "Sales by Customer",
      charttype => { 
        id => "",                #dinamically set by viewer
        class => "widgetType",   #dinamically set by viewer
        options => [ 
          { id => "pie", label => "Pie" },
          { id => "table", label => "Table" }
        ],
      },
      charcolumns => [1], #characteristics columns, type = string
      kfcolumns => [2],   #key figure columns, type = number
      masterdata => 'select distinct id as id, name as label from customer',
      query => "
      SELECT  to_char(ar.transdate, 'YYYY')||to_char(ar.transdate, 'MM') rowkey, customer_id as id,
      ROUND(SUM(ar.netamount)) as total
      FROM ar
      WHERE approved = TRUE
      GROUP BY 1, 2
      ORDER BY 1 DESC, 3 DESC
      ",
    },
    '200sales_pg' => {"id" => "salespg", "source" => "200sales_pg", "title" => "Sales by Product Group",
      charttype => { 
        id => "",                #dinamically set by viewer
        class => "widgetType",   #dinamically set by viewer
        options => [ 
          { id => "pie", label => "Pie" },
          { id => "table", label => "Table" }
        ],
      },
      charcolumns => [1], #characteristics columns, type = string
      kfcolumns => [2],   #key figure columns, type = number
      masterdata => 'select distinct id as id, partsgroup as label from partsgroup',
      query => "
      SELECT  to_char(ar.transdate, 'YYYY')||to_char(ar.transdate, 'MM') rowkey, pg.id as id,
      ROUND(SUM(i.qty * i.fxsellprice * (1-i.discount))) as total
      FROM ar
      JOIN invoice i on (i.trans_id = ar.id)
      JOIN parts p on (p.id = i.parts_id)
      JOIN partsgroup pg on (pg.id = p.partsgroup_id)
      WHERE approved = TRUE
      GROUP BY 1,2
      HAVING SUM(i.qty * i.fxsellprice * (1-i.discount)) != 0
      ORDER BY 1 DESC, 2
      ",
    },
    '300sales_salesman' => {"id" => "salessalesman", "source" => "300sales_salesman", "title" => "Sales by Salesman",
      charttype => { 
        id => "",                #dinamically set by viewer
        class => "widgetType",   #dinamically set by viewer
        options => [ 
          { id => "pie", label => "Pie" },
          { id => "table", label => "Table" }
        ],
      },
      charcolumns => [1], #characteristics columns, type = string
      kfcolumns => [2],   #key figure columns, type = number
      masterdata => 'select distinct id as id, name as label from employee',
      query => "
      SELECT  to_char(ar.transdate, 'YYYY')||to_char(ar.transdate, 'MM') rowkey, ar.employee_id as id,
      ROUND(SUM(ar.netamount)) as total
      FROM ar
      WHERE approved = TRUE
      GROUP BY 1,2
      ORDER BY 1 DESC, 2
      ",
    },
  };

  $self->kpis($initialconfig);
}

sub kpis {
  my( $self, $kpis ) = @_;
  if($kpis) {
    $self->{kpis} = $kpis;
  }
  return $self->{kpis};
}

sub dash {
  my( $self ) = @_;
  my $kpis = $self->kpis();  
  my @data;
  foreach my $k (sort keys %{$kpis}){
    push @data, { 
                  id => $kpis->{$k}->{id}, 
                  source => $kpis->{$k}->{source}, 
                  title => $kpis->{$k}->{title},
                  charttype => $kpis->{$k}->{charttype},
                  charcolumns => $kpis->{$k}->{charcolumns},
                  kfcolumns => $kpis->{$k}->{kfcolumns},
                }
  }
  return { kpis => \@data }
}

#timeframe, depending on model (revenue.is, expenses.ir, orders.oe, etc)
sub timeframe {
  my( $self, $module ) = @_;

  my $disconnect = ($self->{dbh}) ? 0 : 1;
  if (!$self->{dbh}) {
    $self->{dbh} = $self->{form}->dbconnect($self->{myconfig});
  }

  $module = 'AR';
  my $keydate = 'transdate';
  my $slice = "";
  my $maxrows = "";

  my $query = qq|
    SELECT to_char($keydate, 'YYYY') \|\| to_char($keydate, 'MM') as month
    FROM $module as m
    GROUP BY 1
    ORDER BY 1 DESC
  |;

  my $sth = $self->{dbh}->prepare($query);
  $sth->execute || $self->{form}->dberror($query);
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    push @months, $ref->{month};
  }
  $sth->finish;

  if($disconnect) {
    $self->{dbh}->disconnect;
    $self->{dbh} = undef;
  }

  return { months => \@months };
}

# Class to model KPI entity
package KPI;

use parent 'Object::Accessor';
use Switch;

sub new {
  my ($class, $myconfig, $form, $dbh) = @_;
  my $self = {};
  
  $self->{form} = $form;
  $self->{myconfig} = $myconfig;
  $self->{dbh} = $dbh;

  bless $self, $class;

  #$self->mk_accessors();

  return $self;
}


#get key figure data from database
#https://developers.google.com/chart/interactive/docs/reference?hl=es#DataTable
sub keyfigure {
  my ($self, $kpi) = @_;

  my $sth = undef;
  my $mdref = undef;
  my $columns_ref; #HoH with columns labels
  my $ref; #sth data handler
  my @columns; # AoH with columns definition
  my @rows; #AoH with series info

  my $functionprefix = "do_pivot";

  my $disconnect = ($self->{dbh}) ? 0 : 1;
  if (!$self->{dbh}) {
    $self->{dbh} = $self->{form}->dbconnect($self->{myconfig});
  }
  
  $self->{dbh}->{AutoCommit} = 0;

  if($kpi->{masterdata}) {
    $sth = $self->{dbh}->prepare($kpi->{masterdata});
    $sth->execute || $self->{form}->dberror($kpi->{query});
    $mdref = $sth->fetchall_hashref('id');
  }

  if($kpi->{query} =~ m/${functionprefix}/) {
    $self->{dbh}->do($kpi->{query});

    $sth = $self->{dbh}->prepare("FETCH ALL FROM result");
    $sth->execute || $self->{form}->dberror($kpi->{query});
    #while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {
    #  push @months, $ref->{month};
    #}
    $ref = $sth->fetchall_arrayref();
    $self->{dbh}->do("END");

  } else {

    $sth = $self->{dbh}->prepare($kpi->{query});
    $sth->execute || $self->{form}->dberror($kpi->{query});
    $ref = $sth->fetchall_arrayref();
  }

  $columns_ref =  $sth->{NAME};
  $sth->finish;

  if($disconnect) {
    $self->{dbh}->disconnect;
    $self->{dbh} = undef;
  }

  # prepare google charts info structure
  # get cols info
  my $i = 0;
  my $fieldtype;
  my $fieldlabel;
  my $columns_qty = scalar(@{$columns_ref}) - 1 ;
  foreach my $col (@{$columns_ref}){
    $fieldtype = (_grep($i, $kpi->{charcolumns})) ? "string" : "number";
    if($i eq 0){$fieldtype = "string"};
    $fieldlabel = ($mdref->{$col}->{label}) ? $mdref->{$col}->{label} : "";
    if($col eq "total"){$fieldlabel = "TOTAL"}
    if($i == 0){$fieldlabel = "Month"}
    push @columns, {id => $col, label => $fieldlabel, type => $fieldtype };
    $i++;
  }

# get rows info 
  $i = 0;
  foreach my $r (@{$ref}) {
    my (@col, $val);
    $j=0;
    # wtf, using multiplication per 1, we are gonna cast integer values, no support floats
    foreach my $ele (@{$r}) { 
      if( _grep($j, $kpi->{charcolumns}) ){
        $val = $mdref->{''.$ele}->{label}
      } else {
        $val = $ele * 1;
      }
      if($j == 0){ $val = $ele };
      push @col, { v => $val }; 
      $j++  
    }
    push @rows,  { c => \@col } ;
    $i++;
  }

  return { cols => \@columns, rows => \@rows };
  
}

sub _grep {
  my( $value, $array ) = @_;
  if(ref($array) ne 'ARRAY'){ return 0 };
  for (@{$array}) { if( $_ eq $value ) { return 1 } }
  return 0;
}

#EOF
1;
