function transfer_task(id, type){
  var subtask = jQuery("#s_" + id),
      hasParent = subtask.attr("class").match(/child-of-s_\d+/),
      data = "<tr id='transferred_" + id + "' class='odd issue'>" + subtask.html() + "</tr>",
      childId = id,
      parentDOMID = (hasParent ? ("#transferred_" + hasParent[0].match(/\d+/)) : null),
      after = ((hasParent && (jQuery(parentDOMID).length != 0))? parentDOMID : "tr:last");
  if(jQuery("#transferred_" + id).length == 0){
    if(jQuery("#no_tasks_" + type).length == 0){
      jQuery(data).insertAfter("#transfer_table_" + type + " " + after).find(".small").remove();
      jQuery("#transferred_" + id).append("<td class='small'><img width='15' src='/images/arrow_to.png' alt='Arrow_to' onclick=\"undo_transferred(\'" + type + "\'" + ", " + "\'" + id + "\')\"></td>")
    }else{
      jQuery("#no_tasks_" + type).remove();
      jQuery("#transfer_table_" + type).append(data).find(".small").remove();
      jQuery("#transferred_" + id).append("<td class='small'><img width='15' src='/images/arrow_to.png' alt='Arrow_to' onclick=\"undo_transferred(\'" + type + "\'" + ", " + "\'" + id + "\')\"></td>")
    }
    jQuery("#transferred_" + id).append("<input type='hidden' name='transferred_subtasks[]' value='"+ id +"'>");
    subtask.hide();
    
    while(hasParent){
      var parentId = hasParent[0].match(/\d+/),
            subtask2 = jQuery("#s_" + parentId),
            data2 = "<tr id='transferred_" + parentId + "' class='odd issue'>" + subtask2.html() + "</tr>";
      if(jQuery("#transferred_" + parentId).length == 0){
        jQuery(data2).insertBefore("#transfer_table_" + type + " #transferred_" + childId).find(".small").remove();
        jQuery("#transferred_" + parentId).append("<td class='small'></td>")
        if(jQuery("#transferred_" + parentId).find('input').length == 0){
          jQuery("#transferred_" + parentId).append("<input type='hidden' name='parent_tasks[]' value='"+ parentId +"'>");
        }
        hasParent = subtask2.attr("class").match(/child-of-s_\d+/);
        childId= parentId;
      }else{
        break;
      }
    }
  }
  stripe('splittable_list');
  stripe("transfer_table_" + type);
}

function transfer_descendants(descendants, type){
  for(var i=0; i < descendants.length; i++){
    transfer_task(jQuery(descendants[i]).attr("id").match(/\d+$/), type);
    transfer_descendants(jQuery(".child-of-s_" + jQuery(descendants[i]).attr("id").match(/\d+$/)), type);
  }
}

function reset_transferred(type){
  var table1 = jQuery("#splittable_list"),
      table2 = jQuery("#transfer_table_" + type);
  table1.find("tr:hidden").show();
  var table2_rows = table2.find("tbody tr");
  for(var i = 0; i < table2_rows.length; i++){
    var rowId = jQuery(table2_rows[i]).attr('id');
    if(rowId && rowId.match(/transferred_\d+/)){
      jQuery("#" + rowId).remove();
    }
  }
  if(table2.find('tbody tr').length == 0){
    table2.find('tbody')
          .append('<tr id="no_tasks_'+ type +'"><td colspan="4">No task/s found for this user story or feature.</td></tr>');
  }
}


function undo_transferred(type, id){
  var table1 = jQuery("#splittable_list"),
      table2 = jQuery("#transfer_table_" + type),
      subtask = jQuery("#s_" + id),
      hasParent = subtask.attr("class").match(/child-of-s_\d+/);

    while(hasParent){
      parentId = hasParent[0].match(/\d+/);
      jQuery("#splittable_list").find("#s_" + parentId).show();
      jQuery("#transferred_" + parentId).remove();
      subtask = jQuery("#s_" + parentId)
      hasParent = subtask.attr("class").match(/child-of-s_\d+/);
    }

  table1.find("#s_" + id).show();
  var table2_rows = table2.find("tbody tr");
  for(var i = 0; i < table2_rows.length; i++){
    var rowId = jQuery(table2_rows[i]).attr('id');
    if(rowId && rowId.match("transferred_" + id)){
      jQuery("#" + rowId).remove();
    }
  }
  if(table2.find('tbody tr').length == 0){
    table2.find('tbody').append('<tr id="no_tasks_'+ type +'"><td colspan="4">No task/s found for this user story or feature.</td></tr>');
  }
}

function bind_transfer_event(type){
   jQuery("#splittable_list td.small img").unbind("click").click(function(){
      var id = jQuery(this).closest('tr').attr('id').match(/\d+$/);
      if(jQuery(this).closest('tr').hasClass("is_parent")){
        jQuery(this).closest('tr').hide();
        transfer_task(id, type);
        transfer_descendants(jQuery(".child-of-s_" + id), type);
      }else{
        transfer_task(id, type);
      }
    });
}

function init_binding(){
  if(jQuery("#issue-split-form-edit").css('display') == 'none'){
    bind_transfer_event('new');
  }else if(jQuery("#issue-split-form-new").css('display') == 'none'){
    bind_transfer_event('edit');
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
