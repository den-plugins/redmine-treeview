module TreeviewHelper

  def facebox_context_menu_link(name, url, options={})
    options[:class] ||= ''
    if options.delete(:selected)
      options[:class] << ' icon-checked disabled'
      options[:disabled] = true
    end
    if options.delete(:disabled)
      options.delete(:method)
      options.delete(:confirm)
      options.delete(:onclick)
      options[:class] << ' disabled'
      url = "#"
      link_to name, url, options
    else
      facebox_link_to name, {:url => url}, options
    end
  end
  
  def issue_class(issue, children)
    iclass    = "hascontextmenu #{css_issue_classes(issue)} odd " +
                              (issue.parent ? "child-of-issue-#{issue.parent_issue.id} " : "" )
  end
  
  def display_parent_option(issue)
    "##{issue.id}: #{issue.subject}"
  end
  
  def collection_of_parents
    @issue.fixed_version ? @issue.fixed_version.fixed_issues.select {|i| i.children.any? && i.feature?} : []
  end
  
  def options_for_version_select
    @project.versions.empty? ? [] : (@project.versions.sort.collect {|v| [v.name, v.id]})
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
