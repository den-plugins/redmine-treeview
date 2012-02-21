j=jQuery.noConflict();
function stripe(tid){
  jQuery("#"+tid+" tbody tr.issue:visible").filter(":even").addClass("even").end().filter(":odd").removeClass("even");
}

function toggleAll(tid) {
  var table = jQuery("#"+tid);
  if (table.hasClass("collapsed")) {
    table.removeClass("collapsed").addClass("expanded");
    jQuery("#"+tid+" tr").filter(":parent").each(function() { jQuery(this).expand();});
  }else{
    table.removeClass("expanded").addClass("collapsed");
    jQuery("#"+tid+" tr").filter(":parent").each(function() { jQuery(this).collapse();});
  }
}
