var j = jQuery.noConflict();

var CarryOver = {
  init: function() {
    var me = this;
    me.buttons();
  },
  
  buttons: function() {
    j(".transfer_button").live("click", function(){
      var origin_table = j("#splittable_list"),
          transfer_table = j("#transfer_table_new"),
          carried_issues = j("#carry_over_to_issues"),
          issues = (carried_issues.val() != "") ? carried_issues.val().split(",") : [],
          this_issue = j(j(this).parents("tr")[0]);

      if(j(this).hasClass("from")) {
        j("#no_tasks_new").hide();
        j("#new_carry_over_form_submit").removeAttr("disabled")
        issues.push(this_issue.attr("id").replace("s_", ""));
        CarryOver.transfer(this_issue,"from");
        if(origin_table.find("tbody").children(".issue").not(".hidden").length == 0)
          j("#no_tasks_origin").show();
      }
      else if(j(this).hasClass("to")) {
        j("#no_tasks_origin").hide();
        issues = j.grep(issues, function(val) { return val != this_issue.attr("id").replace("s_", ""); });
        CarryOver.transfer(this_issue,"to");
        if(transfer_table.find("tbody").children(".issue").not(".hidden").length == 0) {
          j("#no_tasks_new").show();
          j("#new_carry_over_form_submit").attr("disabled", "disabled")
        }
      }
      carried_issues.val(issues);
    });

    j("#new_iteration").live("click", function(){
      j("#version_name").val("")
      j(".error_message").text("").hide();
      j(".carry-over-options.iteration").addClass("hidden");
      j(".carry-over-options.create_iteration").removeClass("hidden");
    });
    
    j("#create_iteration").live("click", function(){
      version = j("#version_name").val();
      error = j(".error_message");
      unique = true;
      error.html("").hide();
      j("#carry_over_to_fixed_version_id").children("option").each(function(index, val){
        if(val.text.toLowerCase() == version.toLowerCase())
            unique = false
      });

      if(version!="") {
        if(unique) {
          j('#ajax-indicator').show();
          j.ajax({
            type: 'post',
            url: '/treeview/create_iteration',
            data: {'version': version, 'project_id': j("#project_id").val(), 'id': j("#issue_id").val()},
            success: function() {
              j('#ajax-indicator').hide();
              j(".carry-over-options.iteration").removeClass("hidden");
              j(".carry-over-options.create_iteration").addClass("hidden");
            },
            error: function(data) {
              j('#ajax-indicator').hide();
              error.text("Error").show();
            }
          });
        }
        else
          error.html("That iteration name already exists.").show();
      } 
      else
        error.html("Please indicate iteration name.").show();
    });

    j("#cancel_iteration").live("click", function(){
      j(".carry-over-options.iteration").removeClass("hidden");
      j(".carry-over-options.create_iteration").addClass("hidden");
    });
  },
  
  transfer: function(issue, cmd) {
    var hide, show, 
        parent = issue.attr("parent");
    if(cmd=="from") {
      hide = j("#splittable_list");
      hide.find("#"+issue.attr("id")).addClass("hidden");
      show = j("#transfer_table_new");
      show.find("#"+issue.attr("id")).removeClass("hidden");
    } else {
      show = j("#splittable_list");
      show.find("#"+issue.attr("id")).removeClass("hidden");
      hide = j("#transfer_table_new");
      hide.find("#"+issue.attr("id")).addClass("hidden");
    }

    do {
      if(hide.find("tbody").children(".issue").filter("[parent="+parent+"]").not(".hidden").length == 0)
        hide.find("#"+parent).addClass("hidden");
      show.find("#"+parent).removeClass("hidden");
      parent = j(parent).attr("parent");
    } while(j(parent).length > 0)
  }
}

j(document).ready(function(){
  CarryOver.init();
});
