module TreeviewHelper
  
  def issue_class(issue, children)
    iclass    = "hascontextmenu #{css_issue_classes(issue)} odd " +
                              (issue.parent ? "child-of-issue-#{issue.parent_issue.id} " : "" )
  end
  
  def tree_column_header(column)
    if column.sortable
      sort_header_tag(column.name.to_s,
        :caption => column.caption,
        :default_order => column.default_order,
        :class => column.name.to_s)
    else
      content_tag('th', column.caption, :class => column.name.to_s)
    end
  end
end
