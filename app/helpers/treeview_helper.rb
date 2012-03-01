module TreeviewHelper

  def collection_of_features
    @split_features_list.empty? ? [] : @split_features_list.collect {|f| [f.subject, f.id]}
  end

  def collection_of_versions
    @project.versions.empty? ? [] : @project.versions.sort.collect {|v| [v.name, v.id]}
  end
  
  def collection_of_predefined_tasks
    predef_tasks = @split_feature.predef_tasks
    if @split_feature.new_record?
      predef_tasks
    else
      existing_predef_tasks = @split_feature.children.map {|c| c.subject.split("-").first.strip if predef_tasks.member?(c.subject.split("-").first.strip)}.compact
      predef_tasks - existing_predef_tasks
    end
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
    iclass = "hascontextmenu #{css_issue_classes(issue)} odd " +
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
  
  def split_subtask_class(issue)
    iclass = "odd #{css_issue_classes(issue)} " +
                    ((issue.parent and !issue.parent_issue.eql?(@issue)) ? "child-of-s_#{issue.parent_issue.id}" : "") +
                    (issue.children.any? ? " is_parent" : "")
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
  
  def value_for_description
    if @split_feature.new_record?
      @split_features_list.empty? ? "" : @split_features_list.first.description
    else
      @split_feature.description
    end
  end
  
  def value_for_priority_id_selected
    if @split_feature.new_record?
      @split_features_list.empty? ? "" : @split_features_list.first.priority_id
    else
      @split_feature.priority_id
    end
  end
end
