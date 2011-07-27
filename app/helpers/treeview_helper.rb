module TreeviewHelper

  def render_issue_heirarchy(issue, query)
    par = []
    issue_class = "hascontextmenu #{css_issue_classes(issue)} " + 
                         (issue.parent ? "issue-#{issue.parent.other_issue(issue).id} child " : " #{cycle('odd', 'even')} " )
    style = issue.parent.nil? ? "" : "style = 'display: none;' "

    if issue.children.any?
      onclick = ""
      issue.children.each  {|e| onclick << "toggleSub('issue-#{e.id}');"}
      onclick << "toggleIcon('issue-#{issue.id}');"
      issue_class << "close"
    else
      issue_class << "child-p"
    end
  
    par << "<tr id='issue-#{issue.id}' class='#{issue_class}' #{style} >"
    par << "<td class='checkbox'>" + check_box_tag('ids[]', issue.id, false, :id => nil) + "</td>"
    par << "<td><div class='tooltip'>" + link_to(issue.id, :controller => 'issues', :action => 'show', :id => issue) +
                         "<span class='tip'>" + render_issue_tooltip(issue) + "<span>" +
                "</div></td>"
              
    query.columns.each do |column|
      if column.name == :subject
        span = "<span class='treeview'>" + (issue.children.any? ? link_to_remote(".", {}, :onclick => onclick)  : link_to_remote(".")) + "</span>" if issue.children.any? or not issue.parent.nil? 
        par << content_tag('td', (span.nil? ? "" : span) + column_content(column, issue), :class => column.name, :style => "text-indent: #{node_level(issue)*15}px; ")
      else
        par << content_tag('td', column_content(column, issue), :class => column.name)
      end
    end
    
    par << "</tr>"
  
    if issue.children.any?
      issue.children.each do |subtask|
        par << render_issue_heirarchy(subtask, query)
      end
    end
    par
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
