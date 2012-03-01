function transfer_task(id, type){

  var subtask = jQuery("#s_" + id);
  jQuery("#no_tasks_" + type).remove();
  jQuery("#transfer_table_" + type).append("<tr>" + subtask.html() + "</tr>").find(".small").remove();
  jQuery("#transferred_" + type).val(jQuery("#transferred_" + type).val() + id + " ");
  subtask.hide();

}
