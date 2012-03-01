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
