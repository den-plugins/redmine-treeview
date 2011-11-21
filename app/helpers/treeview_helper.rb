module TreeviewHelper

  def column_content_subject(issue)
    value = issue.send(:subject)
    h((@project.nil? || @project != issue.project) ? "#{issue.project.name} - " : '') +
    link_to(h(truncate(value,100)), :controller => 'treeview', :action => 'show', :id => issue)
  end
  
  def node_level(issue)
    l = 0
    until issue.parent.nil?
      l += 1
      issue = issue.parent.other_issue(issue)
    end
    l
  end
end
