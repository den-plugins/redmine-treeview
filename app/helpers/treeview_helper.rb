module TreeviewHelper

  def column_content_subject(issue)
    value = issue.send(:subject)
    h((@project.nil? || @project != issue.project) ? "#{issue.project.name} - " : '') +
    link_to(h(truncate(value,100)), :controller => 'treeview', :action => 'show', :id => issue)
  end
  
  def display_column_details(issue, children, column)
    if column.name.eql?(:subject)
      content_tag('td', (issue_span issue, children) + column_content_subject(issue), :class => column.name, :style => subject_indent(issue))
    else
      content_tag('td', column_content(column, issue), :class => column.name)
    end
  end
  
  def issue_class(issue, children)
    iclass = "hascontextmenu #{css_issue_classes(issue)} odd " +
                              (issue.parent ? "issue-#{issue.parent_issue.id} " : "" );
    if children.any?
      iclass << "close"
    else
      iclass << "child-p" if @child_issues.include?(issue)
    end
    iclass
  end
  
  def issue_onclick(issue, children)
    return nil unless children.any?
    func = ""
    children.each  {|e| func << "toggleSub('issue-#{e.id}');"}
    func << "toggleIcon('issue-#{issue.id}'); stripe('issueslist');"
  end
  
  def issue_span(issue, children)
    "<span class='treeview'>" +
      (children.any? ? image_tag('blank.png', :plugin => 'redmine_treeview', :onclick => issue_onclick(issue, children))  : "<p>-</p>") +
    "</span>"
  end
  
  def issue_style(issue)
    @child_issues.include?(issue) ? "display: none;" : ""
  end
    
  def node_level(issue)
    lvl = 0
    begin
      lvl += 1
      issue = issue.parent_issue
    end until issue.parent.nil? or !@tmp_issues.include?(issue.parent_issue)
    lvl
  end
  
  def subject_indent(issue)
    "text-indent: #{node_level(issue)*25}px;" if @child_issues.include?(issue)
  end
end
