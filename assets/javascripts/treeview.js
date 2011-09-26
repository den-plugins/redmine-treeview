function toggleSub(issue) {
  var el_issue = document.getElementById(issue);
  el_issue.style.display = el_issue.style.display == 'none' ? '' : 'none'
  if (el_issue.style.display == 'none') {
    hideSub(issue);
  }
  document.close();
}

function hideSub(id) {
  var el_group = document.getElementsByClassName(id);
  var el_parent = document.getElementById(id);
  if (el_parent.hasClassName('open')) {
    el_parent.removeClassName('open');
    el_parent.addClassName('close');
  }
  for (var i=0; i<el_group.length;) {
    el_group[i].style.display = 'none';
    hideSub(el_group[i].id);
    i++;
  }
}

function toggleIcon(issue) {
  var el_issue = document.getElementById(issue);
  if (el_issue.hasClassName('close')) {
    el_issue.removeClassName('close');
    el_issue.addClassName('open');
  } else {
    el_issue.removeClassName('open');
    el_issue.addClassName('close');
  }
}

function stripe(tid) {
  jQuery("#"+tid+" tr:visible").filter(":even").addClass("even").end().filter(":odd").removeClass("even");
}
