function transfer_task(id, type){
  var subtask = jQuery("#s_" + id),
      hasParent = subtask.attr("class").match(/child-of-s_\d+/),
      data = "<tr id='transferred_" + id + "'>" + subtask.html() + "</tr>",
      parentDOMID = (hasParent ? ("#transferred_" + hasParent[0].match(/\d+/)) : null),
      after = ((hasParent && (jQuery(parentDOMID).length != 0))? parentDOMID : "tr:last");
  if(jQuery("#transferred_" + id).length == 0){
    if(jQuery("#no_tasks_" + type).length == 0){
      jQuery(data).insertAfter("#transfer_table_" + type + " " + after).find(".small").remove();
    }else{
      jQuery("#no_tasks_" + type).remove();
      jQuery("#transfer_table_" + type).append(data).find(".small").remove();
    }
    jQuery("#transferred_" + type).val(jQuery("#transferred_" + type).val() + id + " ");
    subtask.hide();
    
    while(hasParent){
      var parentId = hasParent[0].match(/\d+/),
            childId = id;
            subtask2 = jQuery("#s_" + parentId),
            data2 = "<tr id='transferred_" + parentId + "'>" + subtask2.html() + "</tr>";
      if(jQuery("#transferred_" + parentId).length == 0){
        jQuery(data2).insertBefore("#transfer_table_" + type + " #transferred_" + childId).find(".small").remove();
        hasParent = subtask2.attr("class").match(/child-of-s_\d+/);
        childId= parentId;
      }else{
        break;
      }
    }
  }

}

function transfer_descendants(descendants, type){
  for(var i=0; i < descendants.length; i++){
    transfer_task(jQuery(descendants[i]).attr("id").match(/\d+$/), type);
  }
}

//jQuery(document).ready(function() {
//  var scroll_text;
//  jQuery("td.ssubject").live("mouseover", function() {
//    var td = jQuery(this);
//    scroll_text = setInterval(function() {scrollText(td)}, 40);
//  });
//  jQuery("td.ssubject").live("mouseout", function() {
//    clearInterval(scroll_text);
//    jQuery(this).find("span.marquish").css({left: 0});
//  });
//});

//var scrollText = function(td) {
//  var m = td.find("span.marquish");
//  var left = m.position().left - 1;
//  if (-left < ((m.width() + parseInt(m.css("padding-left")) + 10) - td.width())) {
//    left = -left > m.width() ? td.width() : left;
//    td.find("span.marquish").css({left: left});
//  }
//}
