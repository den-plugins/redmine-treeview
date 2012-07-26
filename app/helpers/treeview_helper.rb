module TreeviewHelper

  def collection_of_features
    @split_features_list.empty? ? [] : @split_features_list.collect {|f| [f.subject, f.id]}
  end

  def collection_of_carry_over_features
    @carry_over_features_list.empty? ? [] : @carry_over_features_list.collect {|f| [f.subject, f.id]}
  end

  def collection_of_versions
    @project.versions.empty? ? [] : @project.versions.reject{|x| x == @issue.fixed_version}.sort.collect {|v| [v.name, v.id]}
  end
  
  def display_predefined_tasks(issue)
    tasks_list = ""
    predef_tasks = issue.predef_tasks
    if (issue == @issue)
      predef_tasks.each do |ptask|
        tasks_list << content_tag('span', (check_box_tag 'split_to[predefined_tasks][]', ptask) + (h ptask), :class => 'floating')
      end
    else
      existing_predef_tasks = issue.children.map {|c| c.subject.split("-").first.strip if predef_tasks.member?(c.subject.split("-").first.strip)}.compact
      predef_tasks.each do |ptask|
        disabled = existing_predef_tasks.include?(ptask) ? true : false
        tasks_list << content_tag('span', (check_box_tag 'split_to[predefined_tasks][]', ptask, disabled, :disabled => disabled) + (h ptask), :class => 'floating')
      end
    end
    tasks_list
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
                    ((issue.parent && (@tmp_issues).include?(issue.parent_issue)) ? "child-of-issue-#{issue.parent_issue.id} " : "" )
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

  def carry_over?(issue)
      issue.feature? and issue.children.any?
  end
  
  def split_subtask_class(issue)
    iclass = "odd #{css_issue_classes(issue)} " +
                    ((issue.parent and !issue.parent_issue.eql?(@issue)) ? "child-of-s_#{issue.parent_issue.id}" : "") +
                    (issue.children.any? ? " is_parent" : "")
  end

  def carry_over_subtask_class(issue)
    iclass = "odd #{css_issue_classes(issue)} " +
                    ((issue.parent and !issue.parent_issue.eql?(@issue)) ? "child-of-s_#{issue.parent_issue.id}" : "") +
                    (issue.children.any? ? " is_parent" : "")
  end
  
  def subtasks_for_split(feature)
    (feature == @issue) ? [] : feature.children
  end

  def subtasks_for_carry_over(feature)
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

  def value_for_carry_over_description
    if @carry_over_feature.new_record?
      @carry_over_features_list.empty? ? "" : @carry_over_features_list.first.description
    else
      @carry_over_feature.description
    end
  end
  
  def value_for_priority_id_selected
    if @split_feature.new_record?
      @split_features_list.empty? ? "" : @split_features_list.first.priority_id
    else
      @split_feature.priority_id
    end
  end

  def value_for_carry_over_priority_id_selected
    if @carry_over_feature.new_record?
      @carry_over_features_list.empty? ? "" : @carry_over_features_list.first.priority_id
    else
      @carry_over_feature.priority_id
    end
  end

  def no_child_to_carry_over?(params)
    issue = Issue.find params[:id]
    subtasks = issue.children
    can_be_carried_over = 0
    if subtasks.any?
      subtasks.each do |subtask|
        if subtask.can_be_carried_over?
          can_be_carried_over += 1
        end
      end
    end
    can_be_carried_over
  end

  def no_child_to_split?(params)
    issue = Issue.find params[:id]
    subtasks = issue.children
    to_split = 0
    if subtasks.any?
      subtasks.each do |subtask|
        if subtask.is_transferable?
          to_split += 1
        end
      end
    end
    to_split
  end
end
