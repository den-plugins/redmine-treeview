module TreeviewHelper

  def collection_of_features
    @split_features_list.collect {|f| [f.subject, f.id]}
  end

  def collection_of_versions
    versions = @project.versions.empty? ? [] : @project.versions.sort.reject {|v| v if v.fixed_issues.select {|i| splittable?(i)}.empty? }
    versions.collect {|v| [v.name, v.id]}
  end

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
  
  def display_option(issue)
    "##{issue.id} #{issue.subject}"
  end
  
  def image_link_for_split(subtask)
    link_to_remote image_tag('arrow_from.png', :width => 15), :url => {:controller => 'treeview', :action => 'transfer', :id => subtask}
  end
  
  def splittable?(issue)
    issue.feature? and issue.children.any?
  end
  
  def subtasks_for_split(feature)
    (feature == @issue) ? [] : feature.children
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
