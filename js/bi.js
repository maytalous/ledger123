//
// Gabo Reyes 
// github.com/maytalous

function doOpts(div, key, value) {

  if(typeof div === 'undefined') {
    alert("ERROR: No div info for opts function");
    return {};
  }

  if(typeof key === 'undefined') {
    return jQuery.data(div);
  }

  if(typeof value === 'undefined') {
    var value = "";
  }

  return jQuery.data(div,  key,  value);
} //end-of doOpts

function buildArray(l) {
  var foo = [];
  for(var i = 0; i < l; i++){
    foo.push(i);
  }
  return foo;
}

function doChart(div, opts) {
  var staticsOverview = {

    init: function() {
      this.drawChart();
    },

    drawChart: function () {

      var jsonData = $.ajax( 'bi.pl', 
      { async : false, 
        dataType : 'json', 
        data : { 
          'path' : 'bin/mozilla/', 'js' : '1', 
          'action' : 'get', 
          'type' : 'kpi', 
          'kpi' : opts.kpi.source, 
          'login' : opts.login 
        }
      });

      var data = new google.visualization.DataTable(jsonData.responseText);

      var categoryTimeframe = new google.visualization.ControlWrapper({
        'controlType': 'CategoryFilter',                          
        'containerId': document.getElementById('control1' + opts.kpi.index),
        'options': {                                              
          'filterColumnLabel': 'Month',
          'ui': {
            'labelStacking': 'vertical', 
            'selectedValuesLayout': 'aside', 
            'allowTyping': false,
            'allowMultiple': true,
            'allowNone' : false,
            'label' : 'Month '
          }                
        },
        'state' : { 'selectedValues' : data.getDistinctValues(0) }
      });

      var proxyTable = new google.visualization.ChartWrapper({
          'chartType': 'Table',
          'containerId': document.getElementById('proxyTable' + opts.kpi.index),
      });

      var charttype = "";
      switch(opts.kpi.charttype.options[0].id)
      {
        case "table":
          charttype = "Table";
          break;
        case "column":
          charttype = "ColumnChart";
          break;
        case "line":
          charttype = "LineChart";
          break;
        case "pie":
          charttype = "PieChart";
          break;
        default:
          charttype = "LineChart";
      }
      var chartOpts = {};
      chartOpts.chartType = charttype;
      chartOpts.containerId = document.getElementById(opts.kpi.kpiId);
      chartOpts.options = {};

      var chartwrapper = new google.visualization.ChartWrapper(chartOpts);

      var options = {
              width: opts.width, 
      };

      var dashboardElement = document.getElementById('dashboard' + opts.kpi.index);  
      new google.visualization.Dashboard(dashboardElement).
        bind(categoryTimeframe, proxyTable).
          draw(data, options);

      google.visualization.events.addListener(categoryTimeframe, 'ready', readyEvent);
      google.visualization.events.addListener(categoryTimeframe, 'statechange', statechangeEvent);

      function readyEvent(e) {
        chartwrapper.setDataTable(
          google.visualization.data.group(
            proxyTable.getDataTable(), 
            opts.kpi.charcolumns, 
            [{'column':opts.kpi.kfcolumns[0], 'aggregation': google.visualization.data.sum, 'type': 'number'}]
          )
        );
        var cols = buildArray(chartwrapper.getDataTable().getNumberOfColumns());
        chartwrapper.setView(cols);
        chartwrapper.draw();
      }

      function statechangeEvent(e) {
        chartwrapper.setDataTable(
          google.visualization.data.group(
            proxyTable.getDataTable(), 
            opts.kpi.charcolumns, 
            [{'column':opts.kpi.kfcolumns[0], 'aggregation': google.visualization.data.sum, 'type': 'number'}]
          )
        );
        chartwrapper.draw();
      }

    }, //end-of drawChart
  };

  staticsOverview.init();
} // end-of doChart

// ****************
// jQuery functions
// ****************
(function($){

  var widgetsCounter = 0;
  var flagFloatRight = false; // 1st one floats left
 
  buildSelect = function(data) {
    var html = "<select class='" + data.class + "' id='" + data.id + "'>";
    for(var i=0, l=data.options.length; i<l; i++) {
      html += "<option value='" + data.options[i].id + "'>" + data.options[i].label + "</option>";
    };
    html += "</select>";
    return html;
  }

  addWidget = function(widget) {
    //widgetsCounter = widgetsCounter + 1;

    widget.charttype.id = "wt" + widget.index;
    widget.charttype.class = "widgetType";
    
    // initially right is true; so moves to false
    var floatSide = "";
    var cleanFloat = "";
    if(flagFloatRight){
      flagFloatRight = false;
      floatSide = "right";
      cleanFloat = "<div style='clear:both'></div>";
    } else {
      flagFloatRight = true;
      floatSide = "left";
    }

    var htmlWidget = $("\
<!--- init of widget --->\
<div id='" + widget.id + "' class='widget' style='float: " + floatSide + "'>\
<div class='title'><h3>" + widget.title + "</h3></div>\
<div id='control1" + widget.index + "' class='filter' style=''></div>\
<div id='control2" + widget.index + "' class='filter' style='display:none'></div>\
<div id='dashboard" + widget.index + "' class='dash'>\
<div id='proxyTable" + widget.index + "' style='display: none' ></div>\
<div id='" + widget.kpiId + "' class='kpi' >\
<img src='images/spinner.gif' class='spinner' />\
</div>\
</div>\
</div>\
" + cleanFloat + "\
<!--- end of widget --->");

    $("#widgets").append(htmlWidget);
  }

})(jQuery);
